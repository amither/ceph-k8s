#/bin/bash
mv ~/.kube/config ~/.kube/config.bak
opt="-s "https://cls-eimlt94k.ccs.tencent-cloud.com" --username=admin --password=UC9BYV3Earz5PQlC5yg9R4npOE8lHgPj --certificate-authority=cluster.ca"
echo $opt
kubectl $opt label node 172.16.16.11 ceph-mon=enabled ceph-osd=enabled ceph-mgr=enabled ceph-mds=enabled
kubectl $opt label node 172.16.16.13 ceph-mon=enabled ceph-osd=enabled ceph-mgr=enabled ceph-mds=enabled
#kubectl $opt label node 172.16.16.14 ceph-mon=enabled ceph-osd=enabled ceph-mgr=enabled ceph-mds=enabled

kubectl $opt create namespace ceph
kubectl $opt create configmap ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.mon.keyring --namespace=ceph
kubectl $opt create configmap ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
kubectl $opt create configmap ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph

kubectl $opt create -f ceph-rbac.yaml
kubectl $opt create -f service-mon.yaml
kubectl $opt create -f daemonset-mon.yaml

#check if all mons are ready 
while true; do
  desired=`kubectl $opt -n ceph get ds | grep ceph-mon | awk '{print $2}'`
  ready=`kubectl $opt -n ceph get ds | grep ceph-mon | awk '{print $4}'`
  if [[ $desired -eq $ready && $desired > 0 ]]; then
    break
  else
    echo "mon desired[$desired] ready[$ready],wait..."
    sleep 2  
  fi
done 
echo "mon desired[$desired] all ready, mon ok"

kubectl $opt create -f daemonset-mgr.yaml
kubectl $opt create -f daemonset-osd.yaml
kubectl $opt create -f deployment-mds.yaml

#check if all pods are running
while kubectl $opt -n ceph get pods | sed '1d' | grep  -v Running; do
  echo "have pods not running, wait..."
  sleep 2
done
  
#create cephfs
mon_pod=`kubectl $opt -n ceph get pods | grep ceph-mon | awk '{print $1}' | head -n 1`
kubectl $opt -n ceph exec $mon_pod ceph osd pool create cephfs_data 32
kubectl $opt -n ceph exec $mon_pod ceph osd pool create cephfs_metadata 32
kubectl $opt -n ceph exec $mon_pod ceph fs new cephfs cephfs_metadata cephfs_data
 
kubectl $opt -n ceph exec $mon_pod ceph status


