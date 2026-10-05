output "zone_id" {
  description = "ID da hosted zone pública (lida via data source)."
  value       = data.aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "ARN da hosted zone — usar para restringir a policy do ExternalDNS (least privilege)."
  value       = data.aws_route53_zone.this.arn
}

output "name_servers" {
  description = "Nameservers do Route53 — configurar no Namecheap (Custom DNS). Informativo: a zona foi criada à mão."
  value       = data.aws_route53_zone.this.name_servers
}

output "certificate_arn" {
  description = "ARN do certificado ACM wildcard VALIDADO — usar na annotation certificate-arn dos Ingress HTTPS."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  description = "Domínio raiz gerenciado."
  value       = var.domain_name
}
