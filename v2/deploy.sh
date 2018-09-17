#/bin/bash
kubectl label node 172.16.0.5 node-type=storage
kubectl label node 172.16.0.6 node-type=storage
kubectl label node 172.16.0.13 node-type=storage

kubectl create namespace ceph
kubectl create configmap ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.mon.keyring --namespace=ceph
kubectl create configmap ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
kubectl create configmap ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph

kubectl create -f ceph-rbac.yaml
kubectl create -f service-mon.yaml
kubectl create -f daemonset-mon.yaml
kubectl create -f daemonset-mgr.yaml
kubectl create -f daemonset-osd.yaml
kubectl create -f deployment-mds.yaml
