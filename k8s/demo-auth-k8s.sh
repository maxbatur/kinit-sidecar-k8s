#!/bin/bash 

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function find_pod()
{
  labelled=$1
  namespace=$2

  echo $(kubectl get pod -l $labelled -n $namespace -o name --no-headers | head -n 1)
}

function pod_ready()
{
  pod=$1
  namespace=$2

  statusline=$(kubectl get $pod -n $namespace --no-headers)

  ready=$(echo $statusline | awk '{print $2}')

  echo -e "${ready%%/*}"
}

function watch_deploy()
{
  dc=$1
  namespace=$2

  counter=0
  pod=$(find_pod deploymentconfig=$dc $namespace)
  while [[ "$pod" == "" ]]
  do
    echo -e "${GREEN}*** Looking for a pod for $dc in $namespace${NC}"
    sleep 2

    counter=$((counter + 1))
    [[ $counter -gt 15 ]] && echo -e "${RED}*** Gave up looking for pod $pod for $dc in $namespace after 30 seconds${NC}" && break

    pod=$(find_pod deploymentconfig=$dc $namespace)
  done

  counter=0
  echo -e "\n${GREEN}*** Waiting for $pod in $namespace to be ready${NC}"
  while [ $(pod_ready $pod $namespace) -lt 1 ]
  do
    [[ $counter -gt 0 ]] && echo -e "${GREEN}*** Waiting for $pod in $namespace to be ready${NC}"
    sleep 5
    counter=$((counter + 1))
    [[ $counter -gt 20 ]] && echo -e "${RED}*** Gave up waiting for pod $pod in $namespace after 400 seconds${NC}" && break
  done

}


rand_name=$(head /dev/urandom | tr -dc a-z0-9 | head -c 4 ; echo '')

namespace=krb5-$rand_name
echo -e "\n${GREEN}Namespace: $namespace${NC}"

echo -e "\n${GREEN}Deploying krb5-server${NC}"
helm upgrade --install --namespace=$namespace --create-namespace krb5-server ./krb5-server-deploy-helm-chart
echo -e "\n${GREEN}Deploying krb5-client${NC}"
helm upgrade --install --namespace=$namespace --create-namespace krb5-client ./krb5-example-client-deploy-helm-chart

# wait for Pods to start and be running
watch_deploy krb5-server $namespace
watch_deploy krb5-client $namespace

server_pod=$(kubectl get pod -l deploymentconfig=krb5-server -n $namespace -o name)

admin_pwd=$(kubectl logs -c kdc $server_pod -n $namespace | tail -n +1 | head -1 | sed 's/.*Your\ KDC\ password\ is\ //')

app_pod=$(kubectl get pod -l deploymentconfig=krb5-client -n $namespace -o name)

principal=$(kubectl set env $app_pod -n $namespace --list | grep OPTIONS | grep -o "[a-z]*\@[A-Z\.]*")

realm=$(echo $principal | sed 's/[a-z]*\@//')

# create principal
echo -e "\n${GREEN}Creating principal: $principal${NC}"
echo -n $admin_pwd | kubectl exec -i -c kinit-sidecar $app_pod -n $namespace -- kadmin -r $realm -p admin/admin@$realm -q "addprinc -pw redhat -requires_preauth $principal"

# create keytab
echo -e "\n${GREEN}Creating keytab${NC}"
echo -n $admin_pwd | kubectl exec -i -c kinit-sidecar $app_pod -n $namespace -- kadmin -r $realm -p admin/admin@$realm -q "ktadd $principal"

# watch app logs
echo -e "\n${GREEN}Start watching logs for valid kerberos ticket${NC}"
kubectl logs -f $app_pod -n $namespace -c example-app

#Cleanup 
#kubectl get ns -A --no-headers=true | awk '/krb5-/{print $1}' | xargs kubectl delete ns
echo "To cleanup all krb5-* namespaces run: kubectl get ns -A --no-headers=true | awk '/krb5-/{print \$1}' | xargs kubectl delete ns"
