cat <<EOF |kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: $1
spec:
  selfSigned: {}
EOF