provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Token de autenticação no cluster EKS (curto, renovado a cada plan/apply).
# Usa o nome vindo do módulo eks para não resolver antes do cluster existir.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Providers helm e kubernetes apontando para o cluster recém-criado.
# host/CA vêm dos outputs do módulo eks; o token vem do data source acima.
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}
