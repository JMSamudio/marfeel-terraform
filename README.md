# TERRAFORM - MultiEKS

Este proyecto contiene codigo en terarform para crear multiples clusters con argocd en cada uno de ellos.

Se construye utilizando workspaces de terraform `terraform.workspace`. Esto permite tener tantos workspaces como cluster y argocd como se necesite. Para este caso son 3 (dev, stage y production), cada uno de ellos realiza cambios en distintos branchs.

## REQUERIMIENTOS
1. cuenta de aws

### CREDENCIALES

1. aws:
    - `export AWS_ACCESS_KEY_ID=`
    - `export AWS_SECRET_ACCESS_KEY=`

### SCRIPTS
1. iniciar: `terraform init`
2. crear workspaces, por ejemplo stage: `terraform workspace new stage`
3. seleccionar workspace: `terraform workspace select stage`
4. crear plan: `terraform plan`
5. ejecutar: `terraform apply`

## EXPLICACION 
01. vpc:
    - crea una vpc con el nombre del workspace
    - 2 subs privadas y 2 publicas
02. eks:
    - crea un cluster eks con el nombre del workspace en la version 1.27
    - se agregan security groups 
    - nodegroup con el tipo de instancia "m5.large"
03. load-balancer:
    - ingress controller de aws con el nombre del cluster 
04. argo:
    - instala argocd al cluster
    - crea el service de typo NodePort y el ingress para que pueda exponerse a traves de ALB
    - manifiesto para la visualizacion del repo de acuerdo al workspace: `targetRevision:  ${terraform.workspace == "production" ? "main" : terraform.workspace}`

## TEST
Para probar el ingreso a argocd, es necesario modificar la resolucion de nombre localmente en el archivo `/etc/hosts` apuntando a la ip publica generada para el loadbalancer, por ejemplo para el ambiente de dev:

`52.8.203.61 argo-dev.jmsamudio.com`

La credencial se obtiene a traves de este comando:

`kubectl get secret argocd-initial-admin-secret -n argocd --template={{.data.password}} | base64 -d`


## RESULTADO:

Argocd con salida a internet, y con las aplicaciones deployadas:

![image](https://github.com/JMSamudio/marfeel-terraform/assets/3094532/9fdb53d1-9d7b-449b-8524-ad174e7fceb2)


![image](https://github.com/JMSamudio/marfeel-terraform/assets/3094532/7d67d227-d4e9-44e2-b003-b73a1fe7c3b6)

