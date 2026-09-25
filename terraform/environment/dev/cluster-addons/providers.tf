data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

terraform {
  required_version = ">=1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "~> 2.31"
    }

    helm = {
        source = "hashicorp/helm"
        version = "~> 2.14"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

provider "kubernetes" {
    host = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
    kubernetes {
        host = data.aws_eks_cluster.this.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
        token = data.aws_eks_cluster_auth.this.token
    }
}