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


echo "Share privileged pod's serviceaccount with CNI plugin"
[[ -e "/run/secrets/kubernetes.io/serviceaccount/token" ]] && {
  HOLD_D=$HOSTFS/etc/cni/net.d/hold.d/

  mkdir -pv $HOLD_D

  SADST=$HOLD_D/serviceaccount
  mkdir -pv $SADST
  mount -v -o rbind /run/secrets/kubernetes.io/serviceaccount $SADST

  KCDST=$HOLD_D/kubeconfig
  sed "/users:/,/client-key-data/d" $HOSTFS/etc/kubernetes/kubeconfig > $KCDST
}

## DO NOT CONFIGURE DEFAULT POD NETWORK AS WE USE NAD
#echo "Reconfiguring CNI (assumes OCP)"
#test -e $CNICFG
## Check if it's already installed
#grep hold $CNICFG || {
#  jq '.plugins = [{"type": "hold"}] + .plugins' < $CNICFG | tee new.conflist
#  mv -v new.conflist $CNICFG
#}


echo "Ready"
:> $HOSTFS/tmp/hold.log
tail -F $HOSTFS/tmp/hold.log
sleep inf
