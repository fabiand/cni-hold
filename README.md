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
  - `manifests/fedora.yaml` - A yaml to deploy fedora with /hold/,
    it needs to be unhold to be started
  - `manifests/unhold.yaml` - A yaml to /unhold/ a pod and permit it's creation
- Contrib
  - `contrib/watch-and-annotate-pods.sh` - A script to watch for new
    pods and annotate them to be hold

# Deployment
## With minikube

> **Important**
> minikube must be installed

    $ minikube start --cni=bridge --container-runtime cri-o
    $ minikube kubectl -- apply -f manifests/sa.yaml
    $ minikube kubectl -- apply -f manifests/nad.yaml
    $ minikube kubectl -- apply -f manifests/ds.yaml

## With OpenShift

    $ bash to.sh "destroy"
    $ oc delete -f manifests/ds.yaml -f manifests/nad.yaml
    daemonset.apps "cni-hold-agent" deleted
    networkattachmentdefinition.k8s.cni.cncf.io "hold-prototype-cni" deleted
    [fabiand@toolbox cni-hold-prototype (use-ds)]$ bash to.sh deploy
    $ oc project cni-hold-prototype
    Already on project "cni-hold-prototype" on server "https://a1069488d579c4578b18ee70a862d20d-a8037ad35cafec56.elb.us-east-1.amazonaws.com:6443".
    $ oc apply -f manifests/ds.yaml -f manifests/nad.yaml
    daemonset.apps/cni-hold-agent created
    networkattachmentdefinition.k8s.cni.cncf.io/hold-prototype-cni created
    $

# Test

> **Important**
> Plugin must be deployed

```console
$ bash e2e-test.sh
# Assumption: cni-hold has been deployed to the cluster
# Create fedora (it's on-hold by default)
$ kubectl create -f manifests/fedora.yaml
pod/fedora created
(assert:) $ kubectl get pods -o yaml fedora | grep hold_pod_creation | grep true
    hold_pod_creation: "true"
(assert?) True

# Let it be scheduled, and check it is getting created
$ sleep 10s
(assert:) $ kubectl get pods fedora | grep ContainerCreating
fedora   0/1     ContainerCreating   0          10s
(assert?) True

# Wait to ensure it's blocked, and check that it is still not running
$ sleep 30s
(assert:) $ kubectl get pods fedora | grep ContainerCreating
fedora   0/1     ContainerCreating   0          41s
(assert?) True

# Unhold it
$ kubectl patch pod fedora --patch-file manifests/unhold.yaml
pod/fedora patched

# Give CNI some time to pick it up, and check that it's now running
$ sleep 10s
(assert:) $ kubectl get pods fedora | grep Running
fedora   1/1     Running   0          52s
(assert?) True

# Delete it
$ kubectl delete -f manifests/fedora.yaml
pod "fedora" deleted
(assert:) $ kubectl get pods fedora 2>&1 | grep Error 
Error from server (NotFound): pods "fedora" not found
(assert?) True

# The validation has passed! All is well.
PASS
$
```
