(watch-and-annotate-pods.sh)[watch-and-annotate-pods.sh] will watch for all pods in all namespaces and will annotate them with the hold annotation.

The script can obviously be modified.

If more quarantees are required then
- a mutating webhook
- scheduling gates (beta)
can be used
