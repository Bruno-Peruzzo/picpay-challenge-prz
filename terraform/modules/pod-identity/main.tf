# Módulo de permissões dos controllers via EKS Pod Identity.
#
# Contexto: a SCP da organização (nova experiência AWS) nega explicitamente
# iam:CreateOpenIDConnectProvider, o que inviabiliza IRSA (que depende de um
# OIDC provider na conta). O EKS Pod Identity resolve isso: associa uma IAM role
# diretamente a uma service account do cluster (namespace + nome), sem OIDC
# provider. A entrega das credenciais é feita pelo addon eks-pod-identity-agent
# (habilitado no módulo eks).
#
# Vantagem sobre a abordagem anterior (policies na role do node group):
# permissão granular por workload — cada controller recebe só o que precisa,
# em vez de todas as pods do nó herdarem as mesmas permissões.
#
# Usamos o módulo oficial terraform-aws-modules/eks-pod-identity, que cria a IAM
# role, anexa a policy do controller (presets prontos) e cria a associação
# Pod Identity em um só lugar.

# AWS Load Balancer Controller — cria/gerencia os ALBs a partir de Ingress.
module "lb_controller" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "${var.cluster_name}-aws-lbc"

  # Preset oficial com a policy do AWS Load Balancer Controller.
  attach_aws_lb_controller_policy = true

  # A associação precisa casar EXATAMENTE com a service account que o Helm chart
  # do controller vai criar (ver variáveis lb_controller_namespace / _sa).
  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = var.lb_controller_namespace
      service_account = var.lb_controller_service_account
    }
  }
}

# ExternalDNS — cria registros DNS no Route53 a partir dos Ingress/Service.
module "external_dns" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "${var.cluster_name}-external-dns"

  # Preset oficial com a policy do ExternalDNS. Restringe ChangeResourceRecordSets
  # às hosted zones informadas (default "*" enquanto o domínio não existe; quando
  # a hosted zone for criada na Fase 7, passe o ARN real para least privilege).
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = var.external_dns_hosted_zone_arns

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = var.external_dns_namespace
      service_account = var.external_dns_service_account
    }
  }
}

# Amazon EBS CSI Driver — gerencia volumes EBS para PVCs (ex.: Prometheus/Grafana).
#
# O addon precisa de permissão IAM para chamar as APIs de EC2/EBS. Como
# enable_irsa=false e a role do node group NÃO tem a policy de EBS, sem Pod
# Identity o container ebs-plugin cai no fallback da role do nó e recebe 403
# (ec2:DescribeAvailabilityZones), entra em CrashLoopBackOff e o addon fica
# preso em CREATING. serviceAccount e policy confirmados via
# `aws eks describe-addon-configuration` (ebs-csi-controller-sa + AmazonEBSCSIDriverPolicyV2).
#
# IMPORTANTE — por que a associação fica DENTRO do addon (bloco
# pod_identity_association) e não como aws_eks_pod_identity_association separado:
# o Pod Identity injeta a credencial apenas no START do pod (via webhook). Se a
# associação for criada depois que os pods do controller já subiram, eles NÃO
# pegam a credencial e seguem em CrashLoop (foi o que aconteceu). Quando a
# associação é declarada no próprio addon, o EKS gerencia o ciclo e RECICLA os
# pods do controller com a credencial — tornando o apply resiliente a esse timing.

# Cria APENAS a IAM role + policy do EBS CSI (sem associação; a associação é
# feita pelo addon abaixo). create_association=false evita duplicar a associação.
module "ebs_csi" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "${var.cluster_name}-ebs-csi"

  attach_aws_ebs_csi_policy = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  # Versão opcional: se null, a AWS usa a versão default compatível com o cluster.
  addon_version = var.ebs_csi_addon_version

  # Em create/update, se já houver config no cluster, a nossa prevalece (idempotência).
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Associação de Pod Identity gerenciada pelo próprio addon: o EKS garante que a
  # credencial seja entregue e recicla os pods do controller se necessário.
  pod_identity_association {
    role_arn        = module.ebs_csi.iam_role_arn
    service_account = var.ebs_csi_service_account
  }

  tags = var.tags
}
