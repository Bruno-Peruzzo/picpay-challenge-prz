variable "cluster_name" {
  description = "Nome do cluster EKS, usado como prefixo nos nomes das roles."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do provedor OIDC do cluster EKS (saída do módulo eks)."
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "URL do emissor OIDC do cluster (recebida p/ consistência/documentação)."
  type        = string
}

variable "external_dns_hosted_zone_arns" {
  description = "ARNs das hosted zones Route53 que o ExternalDNS pode gerenciar. Idealmente restringir ao ARN real quando o domínio existir."
  type        = list(string)
  default     = ["*"]
}
