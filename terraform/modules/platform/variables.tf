variable "cluster_name" {
  description = "Nome do cluster EKS onde os charts serão instalados."
  type        = string
}

variable "region" {
  description = "Região AWS do cluster (usada pelo AWS Load Balancer Controller)."
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC do cluster (usado pelo AWS Load Balancer Controller)."
  type        = string
}

# --- AWS Load Balancer Controller ---

variable "lb_controller_chart_version" {
  description = "Versão pinada do chart aws-load-balancer-controller (repo eks)."
  type        = string
  default     = "1.11.0"
}

variable "lb_controller_namespace" {
  description = "Namespace do AWS Load Balancer Controller. DEVE casar com a associação de Pod Identity (módulo pod-identity)."
  type        = string
  default     = "kube-system"
}

variable "lb_controller_service_account" {
  description = "Service account do AWS Load Balancer Controller. DEVE casar com a associação de Pod Identity. Pod Identity dispensa annotation de role ARN."
  type        = string
  default     = "aws-load-balancer-controller"
}

# --- ArgoCD ---

variable "argocd_chart_version" {
  description = "Versão pinada do chart argo-cd (repo argoproj)."
  type        = string
  default     = "7.8.2"
}

variable "argocd_namespace" {
  description = "Namespace do ArgoCD."
  type        = string
  default     = "argocd"
}

variable "argocd_ingress_group_name" {
  description = "alb.ingress.kubernetes.io/group.name — permite reaproveitar um mesmo ALB entre Ingress futuros."
  type        = string
  default     = "picpay-public"
}

variable "argocd_hostname" {
  description = "Hostname público do ArgoCD (ex.: argocd.prz-picpay.lat). Vazio => Ingress sem host (ALB responde em qualquer hostname, acesso HTTP via DNS do ALB — comportamento pré-Fase 7)."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN do certificado ACM wildcard para o listener HTTPS do ALB do ArgoCD. Vazio => Ingress só HTTP (sem TLS)."
  type        = string
  default     = ""
}
