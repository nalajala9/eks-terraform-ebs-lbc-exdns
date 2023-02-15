data "aws_availability_zones" "available" {
  state = "available"
}


# data "aws_partition" "current" {}

# data "terraform_remote_state" "eks" {
#   backend = "s3"
#   config = {
#     bucket = "tfstore97"
#     key    = "eks-tf/terraform.tfstate"
#     region = var.region
#   }
# }
# Datasource: EKS Cluster Auth 
# data "aws_eks_cluster_auth" "cluster" {
#   name     = "${var.project}-cluster"
# }

# Datasource: AWS Load Balancer Controller IAM Policy get from aws-load-balancer-controller/ GIT Repo (latest)

# data "http" "lbc_iam_policy" {
#   url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

#   # Optional request headers
#   request_headers = {
#     Accept = "application/json"
#   }
# }

