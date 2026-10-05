terraform {
  # Lock nativo S3 (use_lockfile) exige Terraform >= 1.10.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # helm/kubernetes instalam a Camada 1 de GitOps (LB Controller + ArgoCD)
    # no cluster recém-criado, no mesmo apply da infra.
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
  }
}
