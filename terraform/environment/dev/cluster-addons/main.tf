resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  
    labels = {
        "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "argocd" {
  name = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = var.argocd_chart_version
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name = "server.service.type"
    value = "ClusterIP"
  } 

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  timeout = 600
}

resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.lb_controller_role_arn
    }
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }
}

resource "helm_release" "lb_controller" {
  name = "aws-load-balancer-controller"
  chart = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version = "1.8.1"
  namespace = "kube-system"

  set{
    name = "clusterName"
    value = var.cluster_name
  }

  set {
    name = "serviceAccount.create"
    value = "false"
  }

  set {
    name = "region"
    value = "ap-south-1"
  }

  set {
    name = "serviceAccount.name"
    value = kubernetes_service_account.lb_controller.metadata[0].name
  }

  set {
    name = "vpcId"
    value = var.vpc_id
  }

  depends_on = [ kubernetes_service_account.lb_controller ]
}