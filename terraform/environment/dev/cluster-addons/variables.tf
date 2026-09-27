variable "cluster_name" {
  type = string
}

variable "argocd_namespace" {
  type = string
  default = "argocd"
}

variable "argocd_chart_version" {
  type    = string
  default = "7.7.11"
}

variable "lb_controller_role_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}