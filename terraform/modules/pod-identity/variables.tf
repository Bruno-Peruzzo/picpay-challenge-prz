variable "cluster_name" {
  description = "Nome do cluster EKS onde as associações de Pod Identity serão criadas."
  type        = string
}

# ---------------------------------------------------------------------------
# IMPORTANTE: os pares (namespace, service_account) abaixo DEVEM casar com o que
# o Helm chart de cada controller cria. Se não casarem, a credencial não é
# entregue à pod. Os defaults são os nomes padrão dos charts oficiais.
# Ver docs/DECISOES.md (D18) e docs/STATUS.md para o registro desses nomes.
# ---------------------------------------------------------------------------

variable "lb_controller_namespace" {
  description = "Namespace da service account do AWS Load Balancer Controller (padrão do chart oficial)."
  type        = string
  default     = "kube-system"
}

variable "lb_controller_service_account" {
  description = "Nome da service account do AWS Load Balancer Controller (padrão do chart oficial)."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "external_dns_namespace" {
  description = "Namespace da service account do ExternalDNS."
  type        = string
  default     = "external-dns"
}

variable "external_dns_service_account" {
  description = "Nome da service account do ExternalDNS."
  type        = string
  default     = "external-dns"
}

variable "external_dns_hosted_zone_arns" {
  description = "ARNs das hosted zones Route53 que o ExternalDNS pode gerenciar. Default '*' enquanto o domínio não existe; restringir ao ARN real na Fase 7 (least privilege)."
  type        = list(string)
  default     = ["*"]
}

variable "ebs_csi_service_account" {
  description = "Service account do EBS CSI Driver. Confirmado via describe-addon-configuration: ebs-csi-controller-sa."
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "ebs_csi_addon_version" {
  description = "Versão do addon aws-ebs-csi-driver. Se null, a AWS usa a versão default compatível com o cluster."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags aplicadas ao addon EBS CSI (as demais tags vêm de default_tags do provider)."
  type        = map(string)
  default     = {}
}
