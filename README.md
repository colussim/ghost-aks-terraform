# ghost-aks-terraform
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) ![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Ghost](https://img.shields.io/badge/ghost-000?style=for-the-badge&logo=ghost&logoColor=%23F7DF1E)
![Ghost](https://img.shields.io/badge/MySQL-4479A1.svg?style=for-the-badge&logo=MySQL&logoColor=white)

# Introduction

Ghost is an amazing open-source blogging platform.Managed hosting is available, but if you have a subscription with a cloud provider, it is interesting to deploy your own instance if you have specific needs. 

Several solutions are available:
- Container App : is a fully managed environment that enables you to run microservices and containerized applications on a serverless platform
- kubernetes
- Standalone server (VM)

Let's take a customer case, if we need :
- Scalability
- High Availability (Multi Zone)
- Rapid disaster recovery
- Development agility
- Reduced platform management
- Monitoring
- Security

One important thing is that Ghost does not support load balanced clustering or multi-server configurations of any kind, there should only be one instance of Ghost per site.

To meet these needs and to have sustainability in time I opt for an architecture based on Kubernetes.To simplify the management of the platform, we will use the kubernetes service hosted by Azure : Azure Kubernetes Service (AKS).But this solution can be deployed on any hosted kubernetes service.
Azure Kubernetes Service is a managed container orchestration service based on the open source Kubernetes system, which is available on the Microsoft Azure public cloud. 
An organization can use AKS to handle critical functionality such as deploying, scaling and managing Docker containers and container-based applications.

![Azure AKS, Azure EKS infra](/images/aks1.png)


For the database which is the heart of Ghost I will opt for the Azure Database for MySQL service.

![database](/images/dbmsql.png)

That will meet the needs of : 
- Highly redundant availability at the zone level and within the same zone.
- Data protection with automatic backups
- Predictable performance
- Elastic scaling in seconds.

Moreover, if you do not have a DBA expert in your team 😀, these features require almost no administration.

Last thing, to automate this deployment we will use Terraform.
Terraform is an  open-source infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files that you can version, reuse, and share.

![terraform](/images/terraform.png)

Using Terraform brings several advantages. This tool not only allows configuration management, but also orchestration. It is compatible with a multitude of cloud platforms, including AWS, Azure and Google Cloud Platform. The transfer between cloud providers is very easy.

I have decomposed the Terraform deployment in several steps,to better understand this deployment. Each step corresponds to a workload.then if we want a single wokload we will have to create a main module and different modules for each step.
- Step1 : Deployment of the kubernetes AKS cluster
- Step2 : Deployment of Certification Manager and Ingress Controller
- Step3 : Deployment of Azure Database for MySQL service
- Step4 : Deployment Ghost Production
- Step5 : Deployment Ghost DEV


![ingress](/images/ingress.png)

An ingress controller is a relatively simple Kubernetes object that defines application routing rules. These rules will allow to configure a reverse proxy on the front end of the services.
Without Ingress, Kubernetes services are directly exposed on the Internet.The Ingress controller is positioned at the application level between the Internet and the services.

The importance of monitoring your ingresses cannot be overstressed.The free open-source NGINX version does not support proper monitoring, and this is a huge disadvantage. To be fair, NGINX Plus offers much better monitoring features.
For use in a professional setting I would opt for the plus version, I could also have gone with Traefik whose opensource version brings more features compared to Ingress NGINX with a full access dashboard.

![certmanager](/images/cert-manager.png)

Cert-manager is a Kubernetes add-on module for TLS certificate management. Cert-manager requests certificates, distributes them to Kubernetes containers and automates the certificate renewal process.The certificate manager is used to issue and manage certificates for services. The Certificate manager is based on the <a href="https://github.com/cert-manager/cert-manager" target="jetstack">jetstack/cert-manager project</a>


**Development**

GitHub Actions is a continuous integration/delivery platform that allows you to automate all kinds of things, courtesy of GitHub's servers. Ghost already provides an official GitHub Action for theme deployment.
With this GitHub Action configured, anytime you push an update to your theme, that update will be sent directly to your website. No upload required.
We will create a Ghost deployment GitHub action for each site (Production and Development).
To be notified as soon as there is an event in our Organization on the repositories (created, deleted, archived, not archived, made public, privatized, edited, renamed, or transferred) and a push, we will be able to use the GitHub webhooks to for example receive a message in a Slack channel or in a monitoring application.

![githubaction](/images/githubaction2.gif)

The purpose of this tutorial is to create an AKS cluster (2 nodes) with Terraform and to deploy 2 instances of Ghost (Production and Development).
To expose our Blog services and other services we will deploy an Ingress controller and a certificate manager.

> For this tutorial I did not set up a DNS with a domain, I would use a resolution by hosts file.
> The configuration values for our deployment are defined in the **variables.tf** file of each module.

# Architecture

![archi](/images/archi.png)

![arch2](/images/archi2.png)

# Prerequisites

Before you get started, you’ll need to have these things:
* Terraform > 0.13.x
* kubectl installed on the compute that hosts terraform
* An Azure account 
* Azure CLI 
* <a href="https://stedolan.github.io/jq/" target="jq">JQ</a>
* bash version 4+
* An Azure service principal for terraform.(see<a href="https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash" target="ms"> here</a> for the creation)


# Initial setup

The first thing to set up is your Terraform. We will create an Azure service principal for Terraform.

```

$ git clone https://github.com/colussim/ghost-aks-terraform.git
$ cd ghost-aks-terraform
$ az login

```
>> Note the credentials of the **Azure service principal**, you will need them to modify the providers.tf file of each workload
>> In the Azure provider block defines syntax that allows you to specify your Azure subscription's authentication information.
```
 provider "azurerm" {
  features {}
  subscription_id = "X-X-X-X-X"
  client_id       = "X-X-X-X-X"
  client_secret   = "X-X-X-X-X"
  tenant_id       = "X-X-X-X-X"
} 
```


# Create a simple Azure Kubernetes Service (AKS) with Ingress Controller

## Create a Cluster

Init terraform environement
Do not forget to modify the **providers.tf** file with the authentication information (subscription_id, cliend_id ...)

```
$ cd aks
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v3.54.0
.............

Terraform has been successfully initialized!

```
Create the Terraform plan by executing terraform plan -out out.plan
```
$ terraform plan -out out.plan
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
......
Saved the plan to: out.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "out.plan"

```

Use the **terraform apply out.plan** command to apply the plan.

```
$ terraform apply out.plan
azurerm_kubernetes_cluster.demo: Creating...
azurerm_kubernetes_cluster.demo: Still creating... [10s elapsed]
azurerm_kubernetes_cluster.demo: Still creating... [20s elapsed]
......
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

outputs:

aaz_cluster_endpoint = "drone01-aks01-fkwmnvmk.hcp.westeurope.azmk8s.io"
az_cluster_name = "drone01-aks"
az_resource_group = "demo"
az_virtual_network = "drone01-network"
client_certificate = <sensitive>
kube_config = <sensitive>
run_this_command_to_configure_kubectl = "az aks get-credentials --name drone01-aks --resource-group demo"
```
In a few minutes your AKS cluster is up 😀.

![AKS](/images/k8s.png)

Now run the following command to configure your local environment to be able to manage your AKS Cluster with the kubectl or Lens command or other kubernetes IDE:
```
$ az aks get-credentials --name drone01-aks --resource-group demo
```

Run the following command to list the nodes and availability zone configuration:
```
$ kubectl describe nodes | grep -e "Name:" -e "failure-domain.beta.kubernetes.io/zone"

Name:               aks-drone01pool-30835718-vmss000000
                    failure-domain.beta.kubernetes.io/zone=westeurope-1
Name:               aks-drone01pool-30835718-vmss000001
                    failure-domain.beta.kubernetes.io/zone=westeurope-2
$
```
You can manage your cluster directly on the azure portal, activate the supervision, manage the different events...

![dash](/images/dash.png)

##  Install Certification Manager and Ingress Controler

Init terraform environement
Do not forget to modify the **providers.tf** file with the authentication information (subscription_id, cliend_id ...)

```
$ cd ../ingress
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v3.54.0

Terraform has been successfully initialized!
```

Create the Terraform plan by executing terraform plan -out out.plan
```
$ terraform plan -out out.plan
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
......
......
Saved the plan to: out.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "out.plan"

```

Use the **terraform apply out.plan** command to apply the plan.
```
$ terraform apply out.plan
null_resource.certif_ns_install: Creating...
anull_resourcr.cluster_certif: Still creating... [10s elapsed]
...
...
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

outputs:
ingress_lb_ip = "20.238.184.3"

```

> Note the ip address of the loadbalancer (ingress_lb_ip = "20.238.184.3") you will need for the following steps.

You can check if the Cert-manager is installed with the following command :
```
$ kubectl get pods -n cert-manager
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-6ffb79dfdb-bbjnb             1/1     Running   0          5m
cert-manager-cainjector-5fcd49c96-l69zv   1/1     Running   0          5m
cert-manager-webhook-796ff7697b-4j4cq     1/1     Running   0          5m
$
```

Check the installation  and that the LoadBalancer service has an external public IP assigned:

```
$ kubectl get svc -n ingress-nginx

NAME                                 TYPE           CLUSTER-IP   EXTERNAL-IP    PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.0.26.20   20.238.184.3   80:30996/TCP,443:32405/TCP   10m
ingress-nginx-controller-admission   ClusterIP      10.0.95.23   <none>         443/TCP                      1om
$
```

#  Create a Azure Database for MySQL service.

For the deployment of the mysql service we will use the same virtual network where our AKS service is deployed

Init terraform environement
Do not forget to modify the providers.tf file with the authentication information (subscription_id, cliend_id ...)

```
$ cd ../database
$ terraform init
Initializing the backend...

Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/null v3.2.1
- Using previously-installed hashicorp/azurerm v3.54.0
```
Create the Terraform plan by executing terraform plan -out out.plan
```
$ terraform plan -out out.plan
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
......
......
Saved the plan to: out.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "out.plan"

```

Use the **terraform apply out.plan** command to apply the plan.
```
$ terraform apply out.plan
azurerm_private_dns_zone.default: Creating...
azurerm_subnet.se_ec_subnet: Creating...
...
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

Subnet_id = "db-mysql01.id"
admin_login = "adminghost"
admin_password = <sensitive>
azurerm_mysql_flexible_server = "mysqlfs-ghost01drone"
mysql_flexible_server_database_name = "mysqlfsdb_ghost01drone"
$
```
Our database server is deployed 😀.

The default DNS domain name is : **.mysql.database.azure.com**

the hostname is : **mysqlfs-ghost01drone**

![MYSQL](/images/dbserver.png)

#  Deployment of the Ghost blog service

Init terraform environement
Do not forget to modify the **providers.tf** file with the authentication information (subscription_id, cliend_id ...)
And modify the variable **ingress_loadb_ip** which is in the file **variables.tf** with the ip address of the loadbalancer provided in step 2


```
$ cd ../prod
$ terraform init
Initializing the backend...

Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/null v3.2.1
- Using previously-installed hashicorp/azurerm v3.54.0
```

Create the Terraform plan by executing terraform plan -out out.plan
```
$ terraform plan -out out.plan
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
......
......
Saved the plan to: out.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "out.plan"

```

Use the **terraform apply out.plan** command to apply the plan.
```
$ terraform apply out.plan

Initializing the backend...
data.terraform_remote_state.aks: Reading...
data.local_file.input: Reading...
data.local_file.input: Read complete after 0s [id=4418290c0af661843b28c70f4eb728f4cc462960]
data.terraform_remote_state.aks: Read complete after 0s
data.azurerm_kubernetes_cluster.cluster: Reading...
........

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

url_ghost_web_access = "http://ghost01.droneshuttles.com"
```

Our Ghost instance is deployed 😀.

As mentioned at the beginning of this tutorial, I don't have a DNS zone,so we need to define a hosted name **ghost01.droneshuttles.com** on a client machine (example on my laptop)

Edit the file using sudo /etc/hosts and add this entry:

20.238.184.3 ghost01.droneshuttles.com ghost01

The IP address 20.238.184.3 and the public IP of the ingress controller  service(ip address of the loadbalancer provided in step 2).


Now open a web-browser at **https://ghost01.droneshuttles.com** and check that you can get a response from the service.

![GHOST](/images/ghost.png)

We now need to configure our instance, create at least one user and configure our GitHub integration.
You should connect to the following URL: **https://ghost01.droneshuttles.com/ghost/**

![GHOST setup](/images/ghostsetup.png)

Then you can create your GitHub Action , more information <a href="https://ghost.org/integrations/github/" target="github-ghost">here</a>

# Deployment of the development environment

The development environment will be deployed in a specific namespace : dev-ghost.
For the database we will not use the Azure Database for MySQL service but an instance in POD.
I am not going to describe the installation the steps are the same as the previous one, I gathered all the steps in one.

Init terraform environement
Do not forget to modify the providers.tf file with the authentication information (subscription_id, cliend_id ...)
And modify the variable **ingress_loadb_ip** which is in the file **variables.tf** with the ip address of the loadbalancer provided in step 2

```
$ cd ../dev
$ terraform init
Initializing the backend...

Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/null v3.2.1
- Using previously-installed hashicorp/azurerm v3.54.0
```

Create the Terraform plan by executing terraform plan -out out.plan
```
$ terraform plan -out out.plan
Saved the plan to: out.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "out.plan"
......
```

Use the **terraform apply out.plan** command to apply the plan.
```
$ terraform apply out.plan
kubernetes_namespace.ghost_ns[0]: Creating...
kubernetes_namespace.ghost_ns[0]: Creation complete after 0s [id=dev-ghost1]
kubernetes_secret.mysql_secret: Creating...
...
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.
utputs:

url_ghost_web_access = "http://ghostdev1.droneshuttles.com"
```

Our Ghost instance is deployed 😀.

As mentioned at the beginning of this tutorial, I don't have a DNS zone,so we need to define a hosted name **ghostdev1.droneshuttles.com** on a client machine (example on my laptop)

Edit the file using sudo /etc/hosts and add this entry:

20.238.184.3 ghostdev1.droneshuttles.com ghost01

The IP address 20.238.184.3 and the public IP of the ingress controller  service(ip address of the loadbalancer provided in step 2).


Now open a web-browser at **https://ghostdev1.droneshuttles.com** and check that you can get a response from the service.
![GHOST dev](/images/ghostdev.png)


## Conclusion

With Terraform, booting a AKS cluster can be done with a single command and it only takes some minutes to get a fully functional configuration.
Terraform makes it easy to manage Kubernetes clusters and Kubernetes resources effectively. It gives organizations the opportunity to work with infrastructure-as-code, management of platforms, and also the opportunity to create modules for self-service infrastructure. Terraform Kubernetes provider gives organizations all the required tools necessary to manage Kubernetes clusters in the environment.

Kubernetes brings to your applications :
- Scalability
- High Availability
- Development agility

Using the Azure Database for MySQL service we have a full manager solution for our databases.


## Resources :

[Documentation, Create a Kubernetes cluster with Azure Kubernetes Service using Terraform](https://docs.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-tf-and-aks#set-up-azure-storage-to-store-terraform-state "Microsoft AKS Documentation")

[Documentation, Create an ingress controller in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli "Create an ingress controller in Azure Kubernetes Service (AKS)")

[Documentation, GitHub Actions](https://ghost.org/integrations/github/ "GitHub Actions for Ghost")

[Documentation, Azure Database for MySQ](https://learn.microsoft.com/en-us/azure/mysql/single-server/overview/ "Azure Database for MySQ")
