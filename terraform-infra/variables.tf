variable "instance_type" {}

variable "key_name" {}

variable "pub_key_path" {}

variable "azs" {}

variable "vpc_cidr" {}

variable "default_region" {}

variable "environment" {}

variable "project_name" {}

variable "enable_waf" {}

variable "db_username" {}

variable "rds_password" {
	sensitive = true
}

variable "my_mail" {}

variable "SLACK_WEBHOOK_URL" {}

variable "python_version" {}

variable "ansible_vault_pass" {
	sensitive = true
}

 