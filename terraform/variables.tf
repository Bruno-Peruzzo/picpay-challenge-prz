variable "project" {
  description = "Nome do projeto, usado como prefixo e em tags."
  type        = string
  default     = "picpay-challenge"
}

variable "region" {
  description = "Região AWS onde todos os recursos são criados."
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Ambiente lógico (cluster único neste desafio)."
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Versão do Kubernetes no control plane (N-1 por estabilidade)."
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "Tipos de instância do node group SPOT (lista diversificada e barata)."
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t3.large", "t3a.large"]
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

variable "ecr_repository_name" {
  description = "Nome do repositório ECR da aplicação."
  type        = string
  default     = "picpay-challenge-app"
}
