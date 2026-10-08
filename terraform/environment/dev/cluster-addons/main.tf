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


resource "helm_release" "prometheus" {
  name = "prometheus"
  chart = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  version = "29.35.0"
  namespace = "monitoring"
  create_namespace = true
  timeout = 600

  depends_on = [helm_release.lb_controller]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  version          = "8.5.1"
  namespace        = "monitoring"
  create_namespace = false

  set{
    name = "adminUser"
    value = "admin"
  }

  set_sensitive {
    name = "adminPassword"
    value = "adminPassword" 
  }

set {
    name  = "persistence.enabled"
    value = "false"
  }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-server.monitoring.svc.cluster.local"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }

  depends_on = [helm_release.prometheus]
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

  depends_on = [data.aws_eks_addon.ebs_csi]
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

resource "helm_release" "eck_operator" {
  name             = "elastic-operator"
  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  namespace        = "elastic-system"
  create_namespace = true
  timeout          = 600
  cleanup_on_fail  = true

  depends_on = [kubernetes_storage_class.gp2_csi]
}

resource "helm_release" "fluent_bit" {
  name            = "fluent-bit"
  repository      = "https://fluent.github.io/helm-charts"
  chart           = "fluent-bit"
  namespace       = kubernetes_namespace.logging.metadata[0].name
  timeout         = 600
  cleanup_on_fail = true
  

  values = [file("${path.module}/fluent-bit-values.yaml")]

  depends_on = [helm_release.eck_operator]
}