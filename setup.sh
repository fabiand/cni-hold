#set -xe

x() { echo "+ $@" ; eval "$@" ; }

if [[ "$1" == "openshift" ]];
then
  x "oc project default"
  x "oc apply -f manifests/sa.yaml"
  x "oc adm policy add-cluster-role-to-user cluster-admin -z cni-hold-prototype"
  x "oc adm policy add-scc-to-user privileged cni-hold-prototype"
  x "oc apply -f manifests/ds.yaml"
else
  x "minikube start --cni=bridge --container-runtime cri-o"
  x "minikube kubectl -- apply -f manifests/sa.yaml"
  x "minikube kubectl -- apply -f manifests/ds.yaml"
fi

