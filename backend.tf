terraform {
  backend "s3" {
    bucket = "tfstore97"
    key    = "eks-tf/terraform.tfstate"
    region = "ap-south-1"
  }
}



# dynamodb_table = "<REPLACE_WITH_YOUR_DYNAMODB_TABLENAME>"
# encrypt        = true