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

  # IRSA desabilitado: a SCP da organização (nova experiência AWS) nega
  # explicitamente iam:CreateOpenIDConnectProvider, o que inviabiliza IRSA
  # (IRSA depende de um OIDC provider na conta).
  # Em vez disso usamos EKS Pod Identity: associa uma IAM role diretamente a uma
  # service account (namespace + nome), sem OIDC provider — portanto não esbarra
  # na SCP — e com permissão granular por workload (melhor que compartilhar
  # permissões na role do nó). O agent é instalado via addon eks-pod-identity-agent
  # abaixo, e as associações ficam no módulo pod-identity.
  enable_irsa = false

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Access entry (v20): dá permissão de admin a quem cria o cluster,
  # simplificando o acesso via kubectl logo após o apply.
  enable_cluster_creator_admin_permissions = true

  # Addons gerenciados pela AWS.
  # vpc-cni com before_compute para a rede subir antes dos nós.
  # eks-pod-identity-agent: DaemonSet que entrega credenciais IAM às pods via
  # Pod Identity (substitui o IRSA). Necessário para as associações funcionarem.
  #
  # OBS: o aws-ebs-csi-driver NÃO fica aqui de propósito. Ele precisa de uma
  # associação de Pod Identity para ter permissão IAM; se fosse criado dentro do
  # módulo EKS (que espera o addon ficar ACTIVE), haveria deadlock — o addon não
  # fica ACTIVE sem a associação, e a associação é criada só depois do módulo.
  # Por isso o EBS CSI é criado como aws_eks_addon separado no módulo pod-identity,
  # depois da associação. Ver modules/pod-identity/main.tf.
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {}
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
