set -xe

minikube start --cni=bridge --container-runtime cri-o
minikube kubectl > /dev/null  # We do this to cache kubectl
minikube cp 1-k8s-w-hold.conflist /etc/cni/net.d/1-k8s.conflist
minikube cp hold /opt/cni/bin/
minikube ssh "sudo chmod a+x /opt/cni/bin/hold"
