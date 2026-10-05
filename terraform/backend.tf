terraform {
  backend "s3" {
    bucket = "picpay-challenge-tfstate-390736326016"
    key    = "infra/terraform.tfstate"
    region = "us-east-2"

    use_lockfile = true

    encrypt = true
  }
}
