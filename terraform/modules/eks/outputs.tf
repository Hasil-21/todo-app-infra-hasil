output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "eks-sg" {
  value = aws_security_group.eks.id
}

output "openid_connect_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}

output "openid_connect_url" {
  value = aws_iam_openid_connect_provider.oidc.url
}

output "rds_eks_cluster_sg" {
  value = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}