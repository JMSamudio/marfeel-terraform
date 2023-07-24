# MARFEEL - Prueba Tecnica

**Por: Juan Manuel Samudio**

Este proyecto contiene codigo en terarform para crear multiples cluster e instalcion de argocd.

La mejor manera que encontre reutilizando codigo fue utilizando los workspaces de terraform `terraform.workspace`. Esto permite tener tantos workspaces como cluster y argocd como se necesite. Para este caso son 3 (dev, stage y production), cada uno de ellos realiza cambios en distintos branchs.

## REQUERIMIENTOS
1. cuenta de aws 
2. dominio (jmsamudio.com para el ejemplo)
3. certificado para el dominio y wildcard (jmsamudio.com y *.jmsamudio.com)

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

## RESULTADO:

Argocd con salida a internet, y con las aplicaciones deployadas:

![image](https://github.com/JMSamudio/marfeel-terraform/assets/3094532/9fdb53d1-9d7b-449b-8524-ad174e7fceb2)


![image](https://github.com/JMSamudio/marfeel-terraform/assets/3094532/7d67d227-d4e9-44e2-b003-b73a1fe7c3b6)

