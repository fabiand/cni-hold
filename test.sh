
set -e

c() { echo "# $@" ; }
n() { echo "" ; }
x() { echo "\$ $@" ; eval "$@" ; }
die() { echo "FATAL: $@" ; exit 1 ; }
assert() { echo "(assert) \$ $@" ; eval $@ || die "Assertion ret 0 failed: '$@'" ; echo "(assert) True" ; }

c "Create bb (it's on-hold by default)"
x "kubectl create -f bb.yaml"
assert "kubectl get pods -o yaml busybox | grep hold_pod_creation | grep true"

n
c "Let it be scheduled, and check it is getting created"
x "sleep 10s"
assert "kubectl get pods busybox | grep ContainerCreating"

n
c "Wait to ensure it's blocked, and check that it is still not running"
x "sleep 30s"
assert "kubectl get pods busybox | grep ContainerCreating"

n
c "Unhold it"
x "kubectl patch pod busybox --patch-file unhold.yaml"

n
c "Give CNI some time to pick it up, and check that it's now running"
x "sleep 10s"
assert "kubectl get pods busybox | grep Running"

n
c "Delete it"
x "kubectl delete -f bb.yaml"
assert "kubectl get pods busybox 2>&1 | grep Error "

n
c "The validation has passed! All is well."
