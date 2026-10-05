# Composição da Camada 1 (infraestrutura) na ordem de dependência:
# VPC → EKS → (ECR, IAM/IRSA). Os outputs de um módulo alimentam o próximo.

# Identidade da conta (usada no output account_id).
# As AZs são resolvidas dentro do módulo vpc, não aqui.
data "aws_caller_identity" "current" {}

# (1) Rede base do cluster.
module "vpc" {
  source = "./modules/vpc"

  name         = local.name_prefix
  cluster_name = local.cluster_name
}

# (2) Cluster EKS + node group SPOT (nós nas subnets privadas da VPC).
module "eks" {
  source = "./modules/eks"

  cluster_name       = local.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
}

# (3) Repositório de imagens (independente da rede/cluster).
module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
}

# (4) Permissões dos controllers via EKS Pod Identity + addon EBS CSI.
# A SCP da org bloqueia o OIDC provider (inviabiliza IRSA), então usamos Pod
# Identity: cada controller recebe uma IAM role associada à sua service account,
# sem OIDC provider e com permissão granular por workload. O agent que entrega
# as credenciais é o addon eks-pod-identity-agent (habilitado no módulo eks).
#
# depends_on no módulo eks garante que o cluster, o node group e o
# eks-pod-identity-agent estejam prontos antes de criarmos as associações e o
# addon EBS CSI — este último precisa de nós para os pods subirem e ficar ACTIVE.
module "pod_identity" {
  source = "./modules/pod-identity"

  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}
