
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  
    labels = {
        "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "argocd" {
  name = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "7.7.11"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name = "server.service.type"
    value = "ClusterIP"
  } 

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  set {
    name  = "configs.cm.kustomize\\.buildOptions"
    value = "--enable-helm"
  }

  timeout = 600
}

data "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
}

resource "kubernetes_storage_class" "gp2_csi" {
  metadata {
    name = "gp2-csi"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type = "gp2"
  }

  depends_on = [ data.aws_eks_addon.ebs_csi ]
}