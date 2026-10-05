output "vpc_id" {
  description = "ID da VPC criada."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs das subnets privadas (onde rodam os node groups)."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs das subnets públicas (onde ficam os ELBs públicos)."
  value       = module.vpc.public_subnets
}

output "vpc_cidr_block" {
  description = "Bloco CIDR da VPC."
  value       = module.vpc.vpc_cidr_block
}
