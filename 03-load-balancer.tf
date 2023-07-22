data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${terraform.workspace}"]
      command     = "aws"
    }
  }
}

resource "aws_iam_policy" "worker_policy" {
  depends_on = [
    module.eks
  ]
  name        = "worker-policy-${terraform.workspace}"
  description = "Worker policy for the ALB Ingress"

  policy = file("utils/iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "additional" {
  depends_on = [
    module.eks
  ]
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.worker_policy.arn
  role       = each.value.iam_role_name
}

resource "helm_release" "ingress" {
  depends_on = [
    module.eks
  ]
  name       = "ingress"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.4.6"

  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }
  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }
  set {
    name  = "clusterName"
    value = "${terraform.workspace}"
  }
}