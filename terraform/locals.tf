locals {
  # Nome do cluster derivado do projeto + ambiente → "picpay-challenge-dev".
  cluster_name = "${var.project}-${var.environment}"

  # Prefixo reutilizável para nomear recursos de forma consistente.
  name_prefix = "${var.project}-${var.environment}"
}
