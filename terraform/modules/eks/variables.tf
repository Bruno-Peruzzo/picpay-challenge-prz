variable "cluster_name" {
  description = "Nome do cluster EKS."
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes no control plane (N-1 por estabilidade)."
  type        = string
  default     = "1.36"
}

variable "vpc_id" {
  description = "ID da VPC onde o cluster será criado."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas onde rodam os node groups (multi-AZ)."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Tipos de instância do node group SPOT. Restritos aos elegíveis ao Free Tier (plano FREE da conta): t3.small e *-flex.large (2 vCPU, 4-8 GB)."
  type        = list(string)
  default     = ["t3.small", "m7i-flex.large", "c7i-flex.large"]
}

variable "node_min_size" {
  description = "Número mínimo de nós no node group SPOT."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Número máximo de nós no node group SPOT."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Número desejado de nós no node group SPOT."
  type        = number
  default     = 2
}
