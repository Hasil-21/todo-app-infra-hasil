resource "aws_security_group" "eks" {
    name = "${var.name}-eks-cluster-sg"
    vpc_id = var.vpc_id
    description = "Security Group for EKS"

    egress {
        description = "Allow all outbound"
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.name}-eks-cluster-sg"
    }
}

resource "aws_iam_role" "cluster" {
    name = "${var.name}-eks-cluster-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {Service = "eks.amazonaws.com"}
            Action = "sts:AssumeRole"
        }]
    })

    tags = {
      Name = "${var.name}-eks-cluster-role"
    }
}

resource "aws_iam_role_policy_attachment" "cluster" {
    role = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "cluster" {
    name = "${var.name}-cluster"
    role_arn = aws_iam_role.cluster.arn
    version = "1.31"

    vpc_config {
      subnet_ids = concat(var.public_subnet_ids,var.private_subnet_ids)
      endpoint_public_access = true
      endpoint_private_access = true
    }

    depends_on = [ aws_iam_role_policy_attachment.cluster ]
}

resource "aws_iam_role" "node_group" {
    name = "${var.name}-eks-node-group-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })

    tags = {
      Name = "${var.name}-eks-node-group-role"
    }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
    role = aws_iam_role.node_group.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
    role = aws_iam_role.node_group.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
    role = aws_iam_role.node_group.name 
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "node_group" {
    node_group_name = "${var.name}-eks-node-group"
    cluster_name = aws_eks_cluster.cluster.name
    node_role_arn = aws_iam_role.node_group.arn
    subnet_ids = var.private_subnet_ids

    scaling_config {
      desired_size = 2
      min_size = 1
      max_size = 3
    }

    depends_on = [ 
        aws_iam_role_policy_attachment.node_cni,
        aws_iam_role_policy_attachment.node_ecr,
        aws_iam_role_policy_attachment.node_worker
     ]
}

data "tls_certificate" "oidc" {
    url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = [ data.tls_certificate.oidc.certificates[0].sha1_fingerprint ]
    url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
