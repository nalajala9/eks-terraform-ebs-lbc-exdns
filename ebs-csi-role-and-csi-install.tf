#Get EKS cluster name
# data "aws_eks_cluster" "this" {
#     name = "${var.project}-cluster"
# }

# Get EKS cluster certificate thumbprint
data "tls_certificate" "tls" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Create the OIDC provider

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Datasource: EBS CSI IAM Policy get from EBS GIT Repo (latest)
# data "http" "ebs_csi_iam_policy" {
#   url = "https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/example-iam-policy.json"

#   request_headers = {
#     Accept = "application/json"
#   }
# }

# Resource: Create EBS CSI IAM Policy 
resource "aws_iam_policy" "ebs_csi_iam_policy" {
  name        = "AmazonEKS_EBS_CSI_Driver_Policy"
  path        = "/"
  description = "EBS CSI IAM Policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:AttachVolume",
          "ec2:CreateSnapshot",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DetachVolume",
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}




#On terraform we can get the account ID using the aws_caller_identity datasource:

data "aws_caller_identity" "current" {}


# Resource: Create IAM Role and associate the EBS IAM Policy to it

resource "aws_iam_role" "ebs_csi_iam_role" {
  name = "${var.project}-ebs-csi-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.oidc.arn}"
        }
        Condition = {
          StringEquals = {            
            "${element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc.arn}"), 1)}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "${var.project}-ebs-csi-iam-role"
  }
}

# Associate EBS CSI IAM Policy to EBS CSI IAM Role

resource "aws_iam_role_policy_attachment" "ebs_csi_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.ebs_csi_iam_policy.arn 
  role       = aws_iam_role.ebs_csi_iam_role.name
}

# Install EBS CSI Driver using HELM
# Resource: Helm Release 


resource "helm_release" "ebs_csi_driver" {
  depends_on = [ aws_iam_role.ebs_csi_iam_role ]
  name       = "aws-ebs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"

  namespace = "kube-system"     

#   set {
#     name = "image.repository"
#     value = "602401143452.dkr.ecr.ap-south-1.amazonaws.com/kubernetes-sigs/aws-ebs-csi-driver" # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguoe/add-ons-images.html
#   }       

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.ebs_csi_iam_role.arn}"
  }
    
}


output "aws_iam_openid_connect_provider_arn" {
  description = "AWS IAM Open ID Connect Provider ARN"
  value = aws_iam_openid_connect_provider.oidc.arn 
}

output "ebs_csi_iam_policy_arn" {
  value = aws_iam_policy.ebs_csi_iam_policy.arn 
}

output "ebs_csi_iam_role_arn" {
  description = "EBS CSI IAM Role ARN"
  value = aws_iam_role.ebs_csi_iam_role.arn
}


