#!/usr/bin/bash

set -xe

HOSTFS=/host

test -e $HOSTFS


echo "Check minikube and openshift"
CNICFG=$HOSTFS/etc/cni/net.d/100-crio-bridge.conflist
if [[ -e "$CNICFG" ]]; then
  echo Found openshift
  CNIBINP=$HOSTFS/var/lib/cni/bin
else
  echo Found minikube
  CNICFG=$HOSTFS/etc/cni/net.d/1-k8s.conflist
  CNIBINP=$HOSTFS/opt/cni/bin
fi


echo "Installing plugin"
test -e $CNIBINP
chmod a+x hold
cp -v hold $CNIBINP


echo "Installing kubeconfig from privileged pod"
[[ -e "/run/secrets/kubernetes.io/serviceaccount/token" ]] && {
  mkdir -p $HOSTFS/etc/cni/net.d/hold.d/
  # FIXME will expire after a while
  cp -v /run/secrets/kubernetes.io/serviceaccount/token $HOSTFS/etc/cni/net.d/hold.d/
}

echo "Reconfiguring CNI (assumes OCP)"
test -e $CNICFG
# Check if it's already installed
grep hold $CNICFG || {
  jq '.plugins = [{"type": "hold"}] + .plugins' < $CNICFG | tee new.conflist
  mv -v new.conflist $CNICFG
}


echo "Ready"
sleep inf
