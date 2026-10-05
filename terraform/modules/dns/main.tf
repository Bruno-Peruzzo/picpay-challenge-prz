# Módulo dns — Camada 1 (Fase 7): TLS para expor as apps com HTTPS válido.
#
# Contexto: a nova experiência AWS (plano FREE) NÃO permite registrar domínios
# via Route 53 Domains. O domínio prz-picpay.lat foi comprado FORA da AWS, no
# Namecheap.
#
# DECISÃO (Opção 1): a HOSTED ZONE é um recurso de FUNDAÇÃO, criado À MÃO fora do
# Terraform (como o bucket do tfstate, D13), e NÃO é gerenciada por este state.
# Motivo: recriar a zona muda os 4 nameservers, obrigando a reconfigurar o
# Namecheap a cada destroy/apply. Mantê-la fora do ciclo preserva os NS e deixa
# o `terraform destroy` do cluster livre e barato. Aqui a zona é apenas LIDA via
# data source; o Terraform gerencia só o certificado ACM (barato de recriar: a
# validação DNS reconclui sozinha enquanto a zona persistir).
#
# ExternalDNS (Camada 2, GitOps) cria os registros dos subdomínios
# (argocd/grafana/app) automaticamente a partir do host de cada Ingress — por
# isso NÃO declaramos esses registros aqui.

# ---------------------------------------------------------------------------
# 1. Hosted zone (LIDA, não gerenciada) — criada à mão via CLI/console
# ---------------------------------------------------------------------------
# private_zone=false garante que pegamos a zona PÚBLICA, caso exista também uma
# privada com o mesmo nome.
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# ---------------------------------------------------------------------------
# 2. Certificado ACM wildcard
# ---------------------------------------------------------------------------
# Um único cert cobre o apex (prz-picpay.lat) e qualquer subdomínio de 1 nível
# (*.prz-picpay.lat): argocd/grafana/app e futuros, sem reemitir. Validação DNS
# porque é 100% automatizável no Route53 e renova sozinha (o ACM mantém o
# registro de validação permanente na zona).
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Registros CNAME de validação do ACM, criados na hosted zone existente.
# for_each dedupe por domain_name (apex + wildcard costumam compartilhar o mesmo
# registro de validação).
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Espera a validação concluir. Depende dos NS do Namecheap já apontarem para a
# zona do Route53; se ainda não foram trocados, esta validação NÃO conclui.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
