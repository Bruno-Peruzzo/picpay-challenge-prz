output "lb_controller_role_arn" {
  description = "ARN da role IAM do AWS Load Balancer Controller."
  value       = module.lb_controller_irsa.iam_role_arn
}

output "external_dns_role_arn" {
  description = "ARN da role IAM do ExternalDNS."
  value       = module.external_dns_irsa.iam_role_arn
}
