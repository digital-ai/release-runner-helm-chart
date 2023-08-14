helm upgrade --install $1 . --values $2 --set diagnosticMode.enabled=true -n $3
