# Get Ingress IP Load Balancer
#! /bin/bash
set -e

LDB=`kubectl -n ingress-nginx get services ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
jq -n --arg ipldb "$LDB" '{"ipldb":$ipldb}'
