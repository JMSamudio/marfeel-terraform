resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"
}

resource "kubectl_manifest" "argocd-service" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  annotations:
    alb.ingress.kubernetes.io/backend-protocol-version: HTTP2 #This tells AWS to send traffic from the ALB using HTTP2. Can use GRPC as well if you want to leverage GRPC specific features
  labels:
    app: argogrpc
  name: argogrpc
  namespace: argocd
spec:
  ports:
  - name: "443"
    port: 443
    protocol: TCP
    targetPort: 8080
  selector:
    app.kubernetes.io/name: argocd-server
  sessionAffinity: None
  type: NodePort
YAML
}

resource "kubectl_manifest" "argocd-ingress" {
    yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/group.name: alb-marfeel-${terraform.workspace}
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: 'ip'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/subnets: ${module.vpc.public_subnets[0]} , ${module.vpc.public_subnets[1]}
    # Use this annotation (which must match a service name) to route traffic to HTTP2 backends.
    alb.ingress.kubernetes.io/conditions.argogrpc: |
      [{"field":"http-header","httpHeaderConfig":{"httpHeaderName": "Content-Type", "values":["application/grpc"]}}]
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:405632504902:certificate/4e06880c-18b5-427c-b231-e970e33a416c
  name: argocd
  namespace: argocd

spec:
  ingressClassName: alb
  rules:
  - host: argo-${terraform.workspace}.jmsamudio.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: argogrpc
            port:
              number: 443
        pathType: Prefix
      - path: /
        backend:
          service:
            name: argocd-server
            port:
              number: 443
        pathType: Prefix
  tls:
  - hosts:
    - argo-${terraform.workspace}.jmsamudio.com
YAML
  
}


resource "kubectl_manifest" "argocd-application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps-staging
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/JMSamudio/marfeel-app.git
    targetRevision: ${terraform.workspace == "production" ? "main" : terraform.workspace}
    path: enviroments/apps
  destination: 
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - Validate=true
      - CreateNamespace=false
      - PrunePropagationPolicy=foreground
      - PruneLast=true
YAML
}