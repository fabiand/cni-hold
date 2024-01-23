A protoype of a CNI plugin to hold the creation of a pod network
namespace - and thus the pod itself - until the pod annotation
`prevent_pod_creation` is set to `false`.

[contrib/watch-and-annotate-pods.sh](contrib/watch-and-annotate-pods.sh)
is an example script to automatically set this annotation for every
new pod.

# Issues

- CNI plugin MUST be the first in the chain
- Deletion of a pod is blocked until the annotation is true

# Files

- CNI Plugin
  - `cni/hold` - The CNI plugin itself
- Container Image for deployment
  - `image/Containerfile` - UBI with script for deploying the CNI config
  - `mage/entry.sh` - Script to deploy the CNI plugin and reconfigure CNI
- Test
  - `e2e-test.sh` - Validate that the plugin is working as expected
  - `manifests/bb.yaml` - A yaml to deploy busybox with /hold/,
    it needs to be unhold to be started
  - `manifests/unhold.yaml` - A yaml to /unhold/ a pod and permit it's creation
- Contrib
  - `contrib/watch-and-annotate-pods.sh` - A script to watch for new
    pods and annotate them to be hold

# Deployment
## With minikube

> **Important**
> minikube must be installed

    $ setup.sh
    + minikube start --cni=bridge --container-runtime cri-o
    + minikube kubectl -- apply -f manifests/sa.yaml
    + minikube kubectl -- apply -f manifests/ds.yaml
    $

## With OpenShift

    $ setup.sh openshift
    + oc project default
    Already on project "default" on server "https://...".
    + oc apply -f manifests/sa.yaml
    serviceaccount/cni-hold-prototype unchanged
    + oc adm policy add-cluster-role-to-user cluster-admin -z cni-hold-prototype
    clusterrole.rbac.authorization.k8s.io/cluster-admin added: "cni-hold-prototype"
    + oc adm policy add-scc-to-user privileged cni-hold-prototype
    clusterrole.rbac.authorization.k8s.io/system:openshift:scc:privileged added: "cni-hold-prototype"
    + oc apply -f manifests/ds.yaml
    daemonset.apps/cni-hold-agent created
    $

# Test

> **Important**
> Plugin must be deployed

```console
$ bash e2e-test.sh
# Create bb (it's on-hold by default)
$ kubectl create -f bb-on-hold.yaml
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
$
```
