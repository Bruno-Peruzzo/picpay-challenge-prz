# Módulo dns — hosted zone Route53 + certificado ACM wildcard (Camada 1, Fase 7).

variable "domain_name" {
  description = "Domínio raiz gerenciado neste projeto (registrado fora da AWS, no Namecheap). Ex.: prz-picpay.lat"
  type        = string
}

variable "tags" {
  description = "Tags extras aplicadas à hosted zone e ao certificado (as demais vêm de default_tags do provider)."
  type        = map(string)
  default     = {}
}
