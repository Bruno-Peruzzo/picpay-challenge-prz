variable "name" {
  description = "Nome da VPC (usado como prefixo nos recursos de rede)."
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS, usado nas tags de discovery das subnets."
  type        = string
}

variable "cidr" {
  description = "Bloco CIDR da VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs_count" {
  description = "Quantidade de AZs a utilizar (3 para alta disponibilidade)."
  type        = number
  default     = 3
}
