# Módulo EKS — encapsula o módulo oficial terraform-aws-modules/eks/aws (série v20).
# Provisiona control plane, addons gerenciados, IRSA e um node group SPOT.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = var.cluster_name

  # Versão N-1 (decisão D14): a mais recente é 1.37; usamos 1.36 por estabilidade
  # em vez de bleeding edge. Ajustável pela variável cluster_version.
  cluster_version = var.cluster_version

  # Endpoint público facilita acesso de kubectl/CI no escopo do desafio.
  # Trade-off de segurança: em produção, restringir por
  # cluster_endpoint_public_access_cidrs ou usar apenas endpoint privado.
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Logging do control plane para auditoria/segurança.
  # Custo: logs vão para CloudWatch Logs (cobrança por ingestão/retenção).
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # IRSA (IAM Roles for Service Accounts): necessário p/ LB Controller e ExternalDNS.
  enable_irsa = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Access entry (v20): dá permissão de admin a quem cria o cluster,
  # simplificando o acesso via kubectl logo após o apply.
  enable_cluster_creator_admin_permissions = true

  # Addons gerenciados pela AWS.
  # vpc-cni com before_compute para a rede subir antes dos nós.
  # aws-ebs-csi-driver incluído (trivial) p/ PVC do Prometheus/Grafana.
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {}
  }

  # Node group SPOT — ver detalhes das variáveis abaixo.
  eks_managed_node_groups = {
    spot = {
      capacity_type = "SPOT"

      # Lista diversificada de tipos baratos equivalentes (decisão D3):
      # diversificar reduz o risco de interrupção SPOT simultânea.
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      labels = {
        role     = "general"
        capacity = "spot"
      }

      # NÃO repetir Project/Environment/ManagedBy — já vêm de default_tags.
      tags = {
        NodeGroup = "spot"
      }

      # Resiliência durante upgrades: no máx. 33% dos nós indisponíveis por vez.
      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }
}
