IMG_REPO=quay.io/fdeutsch/cni-hold-prototype

build() {
	podman -r build -t $IMG_REPO -f image/Containerfile .
}

push() {
	podman -r push $IMG_REPO
}

_oc() { echo "$ oc $@" ; oc $@ ; }
qoc() { oc $@ > /dev/null 2>&1; }

apply() {
	_oc apply -f manifests/ds.yaml
}

deploy() {
	local NS=cni-hold
	qoc get project cni-hold || _oc adm new-project $NS
	_oc project $NS
	qoc get sa -n $NS cni-hold || {
		_oc create sa -n $NS cni-hold
		#oc adm policy add-role-to-user -n $NS cluster-admin -z cni-hold
		_oc adm policy add-cluster-role-to-user cluster-admin -z cni-hold
		_oc adm policy add-scc-to-user -n $NS privileged -z cni-hold
	}
	apply
}

destroy() {
	_oc delete -f manifests/ds.yaml
}

eval "$@"
