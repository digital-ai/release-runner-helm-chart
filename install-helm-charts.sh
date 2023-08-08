helm dependency update .
helm install $1 . --values $2 -n $3
