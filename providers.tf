terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# data "aws_eks_cluster" "this" {
#   name = "${var.project}-cluster"
# }

data "aws_eks_cluster_auth" "cluster" {
  name     = "${var.project}-cluster"
}

provider "helm" {
  kubernetes {
    host                   = "${aws_eks_cluster.this.endpoint}"
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Terraform Kubernetes Provider
provider "kubernetes" {
  host = "${aws_eks_cluster.this.endpoint}"
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
}