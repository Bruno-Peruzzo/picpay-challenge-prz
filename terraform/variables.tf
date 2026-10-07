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
  description = "Tipos de instância do node group SPOT. Restritos aos elegíveis ao Free Tier (plano FREE da conta): t3.small e os *-flex.large (2 vCPU, 4-8 GB) dão RAM suficiente p/ observabilidade; lista diversificada reduz risco de interrupção SPOT."
  type        = list(string)
  default     = ["t3.small", "m7i-flex.large", "c7i-flex.large"]
}

variable "node_min_size" {
  description = "Número mínimo de nós no node group SPOT."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Número máximo de nós no node group SPOT."
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Número desejado de nós no node group SPOT."
  type        = number
  default     = 3
}

variable "ecr_repository_name" {
  description = "Nome do repositório ECR da aplicação."
  type        = string
  default     = "picpay-challenge-app"
}

variable "domain_name" {
  description = "Domínio raiz (registrado no Namecheap; hosted zone criada à mão no Route53). Usado pelo módulo dns (ACM wildcard) e pelo ExternalDNS."
  type        = string
  default     = "prz-picpay.lat"
}
