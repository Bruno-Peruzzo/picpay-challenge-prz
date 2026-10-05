# Módulo VPC — encapsula o módulo oficial terraform-aws-modules/vpc/aws.
# Cria a rede base do cluster EKS: subnets públicas/privadas em 3 AZs,
# NAT gateway e tags de discovery exigidas pelo Kubernetes/ELB.

# AZs disponíveis na região (pega as 3 primeiras: us-east-2a/b/c).
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  # 3 AZs para alta disponibilidade do control plane e dos nós.
  azs = slice(data.aws_availability_zones.available.names, 0, var.azs_count)

  # Subnets privadas /19 (muitos IPs p/ pods via VPC-CNI) e públicas /20.
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  public_subnets  = ["10.0.96.0/20", "10.0.112.0/20", "10.0.128.0/20"]

  # NAT único: reduz custo em dev (~US$0,045/h por NAT + tráfego).
  # Trade-off: ponto único de saída de rede, aceitável no escopo do desafio.
  enable_nat_gateway = true
  single_nat_gateway = true

  # DNS necessário para o EKS resolver nomes internos e para o VPC-CNI.
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags de discovery: o AWS Load Balancer Controller usa estas tags para
  # decidir em quais subnets criar ELBs públicos (elb) e internos (internal-elb).
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
