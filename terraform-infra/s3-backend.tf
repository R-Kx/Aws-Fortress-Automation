terraform {
    backend "s3" {
        profile  = "default"
        bucket   = "r-kx-terraform-storage-123"
        key      = "dev.terraform.tfstate"
        encrypt  = true
        region   = "eu-central-1"
        #dynamodb_table = "flask_db_lock" 
    }
}
data "aws_caller_identity" "current" {}