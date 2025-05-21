
/*
terraform {
  backend "s3" {
    bucket       = "prometheus-terraform-state"
    key          = "terraform.tfstate"
    use_lockfile = false
    encrypt      = true
    region       = "us-east-1"
  }
}
*/