locals {
  # TLS liga quando um cert ACM é fornecido. Sem cert: só HTTP (comportamento
  # pré-Fase 7). Com cert: ALB escuta 80 e 443, redireciona 80->443, e usa o
  # cert no listener HTTPS.
  argocd_tls_enabled = var.acm_certificate_arn != ""

  # Annotations do Ingress do ArgoCD, montadas como MAPA e serializadas via
  # yamlencode. Por que não usar blocos `set` do provider helm: o `set` divide
  # o valor por vírgula, então um valor como '[{"HTTP":80},{"HTTPS":443}]'
  # quebra ("has no value"). Passar tudo por `values` (YAML) evita isso.
  argocd_ingress_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/group.name"   = var.argocd_ingress_group_name
      "alb.ingress.kubernetes.io/listen-ports" = local.argocd_tls_enabled ? "[{\"HTTP\":80},{\"HTTPS\":443}]" : "[{\"HTTP\":80}]"
    },
    local.argocd_tls_enabled ? {
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    } : {}
  )

  # Bloco de values do Helm do ArgoCD (server.insecure + Ingress completo).
  argocd_values = yamlencode({
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    server = {
      ingress = {
        enabled          = true
        ingressClassName = "alb"
        # hostname: Fase 7 recebe argocd.<domínio>; vazio => Ingress sem host.
        hostname    = var.argocd_hostname
        annotations = local.argocd_ingress_annotations
      }
    }
  })
}

# Módulo platform — Camada 1 do GitOps (bootstrap).
#
# Instala, via Helm, os dois componentes que precisam existir ANTES do App of
# Apps do ArgoCD assumir o resto:
#   1. AWS Load Balancer Controller — materializa Ingress em ALBs reais.
#   2. ArgoCD — o motor de GitOps, exposto por um Ingress ALB.
#
# Ambos usam EKS Pod Identity para permissão (a associação do LB Controller é
# criada no módulo pod-identity; aqui só criamos a service account com o nome
# que casa com aquela associação — Pod Identity dispensa annotation de role ARN).

# ---------------------------------------------------------------------------
# 1. AWS Load Balancer Controller
# ---------------------------------------------------------------------------
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lb_controller_chart_version
  namespace  = var.lb_controller_namespace

  # Espera os pods ficarem Ready: assim, quando o ArgoCD Ingress for criado,
  # o controller já existe para materializar o ALB.
  wait    = true
  timeout = 600

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # Service account criada pelo chart com o nome que casa com a associação de
  # Pod Identity. NÃO anotar com eks.amazonaws.com/role-arn (isso é de IRSA;
  # Pod Identity entrega a credencial pelo agent).
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = var.lb_controller_service_account
  }
}

# ---------------------------------------------------------------------------
# 2. ArgoCD
# ---------------------------------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true

  wait    = true
  timeout = 600

  # Toda a configuração vai por `values` (YAML) em vez de blocos `set`:
  # - server.insecure=true: o ALB termina/encaminha HTTP; o argocd-server não
  #   faz TLS próprio (senão vira HTTPS duplo e dá redirect loop).
  # - server.ingress: Ingress ALB internet-facing, hostname + annotations
  #   (HTTP, ou HTTP+HTTPS quando há cert ACM). Ver locals acima.
  values = [local.argocd_values]

  # Garante que o LB Controller exista antes do Ingress do ArgoCD ser criado,
  # para o ALB ser provisionado sem o Ingress ficar órfão.
  depends_on = [helm_release.aws_lb_controller]
}
