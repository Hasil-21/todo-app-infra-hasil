data "aws_iam_policy_document" "lb_controller_assume_role"{
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]

        principals{
            type = "Federated"
            identifiers = [var.openid_connect_arn]
        }

        condition {
            test = "StringEquals"
            variable = "${replace(var.openid_connect_url,"https://","")}:sub"
            values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
        }

        condition {
          test = "StringEquals"
          variable = "${replace(var.openid_connect_url,"https://","")}:aud"
          values = ["sts.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "lb_controller" {
    name = "${var.name}-lb-controller-role"
    assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json
}

resource "aws_iam_policy" "lb_controller" {
    name = "${var.name}-AWSLoadBalancerControllerIAMPolicy"
    policy = file("${path.module}/iam_policy_lb_controller.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}


data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.openid_connect_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.openid_connect_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.openid_connect_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
}