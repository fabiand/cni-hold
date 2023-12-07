#!/usr/bin/bash

c() { echo "# $@" ; }
x() { echo "\$ $@" ; eval "$@" ; }

oc get pods --watch --all-namespaces \
  -o jsonpath='{.metadata.namespace}{" "}{.metadata.name}{"\n"}' \
  | while read N_POD;
    do
      c "Handling pod '$N_POD'"
      x oc annotate pod -n $N_POD hold_pod_creation=true
    done
