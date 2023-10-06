A protoype of a CNI plugin to hold the creation of a pod network
namespace - and thus the pod itself - until the pod annotation
`prevent_pod_creation` is set to `false`.

# Issues

- CNI plugin MUST be the first in the chain
- Deletion of a pod is blocked until the annotation is true

# Files

* `setup.sh` - Configure minikube with this custom CNI plugin
- `test.sh` - Validate that the plugin is working as expected
- `hold` - The CNI plugin itself
- `unhold.yaml` - A yaml to /unhold/ a pod and permit it's creation

# Setup

minikube must be installed locally

```
$ bash setup.sh
+ minikube start --cni=bridge --container-runtime cri-o
+ minikube kubectl
+ minikube cp 1-k8s-w-hold.conflist /etc/cni/net.d/1-k8s.conflist
+ minikube cp hold /opt/cni/bin/
+ minikube ssh 'sudo chmod a+x /opt/cni/bin/hold'
$
```

# Test

```
$ bash test.sh
# Create bb (it's on-hold by default)
$ kubectl create -f bb.yaml
pod/busybox created
(assert) $ kubectl get pods -o yaml busybox | grep hold_pod_creation | grep true
    hold_pod_creation: "true"
(assert) True

# Let it be scheduled, and check it is getting created
$ sleep 10s
(assert) $ kubectl get pods busybox | grep ContainerCreating
busybox   0/1     ContainerCreating   0          11s
(assert) True

# Wait to ensure it's blocked, and check that it is still not running
$ sleep 30s
(assert) $ kubectl get pods busybox | grep ContainerCreating
busybox   0/1     ContainerCreating   0          41s
(assert) True

# Unhold it
$ kubectl patch pod busybox --patch-file unhold.yaml
pod/busybox patched

# Give CNI some time to pick it up, and check that it's now running
$ sleep 10s
(assert) $ kubectl get pods busybox | grep Running
busybox   1/1     Running   0          51s
(assert) True

# Delete it
$ kubectl delete -f bb.yaml
pod "busybox" deleted
(assert) $ kubectl get pods busybox 2>&1 | grep Error 
Error from server (NotFound): pods "busybox" not found
(assert) True

# The validation has passed! All is well.
```


