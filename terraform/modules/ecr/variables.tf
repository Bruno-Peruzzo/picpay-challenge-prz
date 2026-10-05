variable "repository_name" {
  description = "Nome do repositório ECR."
  type        = string
  default     = "picpay-challenge-app"
}

variable "keep_last_images" {
  description = "Quantidade de imagens tageadas a manter (lifecycle policy)."
  type        = number
  default     = 10
}

variable "untagged_expire_days" {
  description = "Dias após os quais imagens não-tageadas são expiradas."
  type        = number
  default     = 7
}
