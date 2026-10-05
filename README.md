# PicPay Challenge — EKS + Observabilidade + GitOps

Provisionamento de um cluster **Amazon EKS** com **Terraform**, rodando uma
aplicação em **Go** instrumentada com **Prometheus/Grafana**, exposta
publicamente via **ALB + HTTPS**, com **CI/CD (GitHub Actions)** e
**GitOps (ArgoCD)**.

## Arquitetura em duas camadas

O projeto separa infraestrutura de workloads para permitir `destroy` barato
sem perder configuração:

- **Camada 1 — Infra (Terraform)**: VPC, EKS, node groups SPOT, ECR, IAM/IRSA,
  ACM, Route53, bootstrap do ArgoCD. É o que o `terraform destroy` remove.
- **Camada 2 — Workloads (GitOps/ArgoCD)**: controllers (AWS LB Controller,
  ExternalDNS), observabilidade (kube-prometheus-stack) e a aplicação. Tudo
  declarativo no Git; reinstala sozinho via App of Apps após recriar a infra.

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `terraform/` | IaC modular da infraestrutura (Camada 1) |
| `app/` | Aplicação Go (`/`, `/health`, `/ready`, `/metrics`) + Dockerfile |
| `helm/` | Helm chart da aplicação com HA (PDB, anti-affinity, HPA, probes) |
| `gitops/` | Manifests ArgoCD (App of Apps) para a Camada 2 |
| `.github/workflows/` | Pipelines de CI/CD (build, push ECR, bump GitOps) |

## Stack

- **Cloud**: AWS (região `us-east-2`)
- **IaC**: Terraform (backend remoto S3 + lock DynamoDB)
- **Compute**: EKS com node group SPOT multi-AZ
- **Registry**: Amazon ECR
- **Observabilidade**: kube-prometheus-stack (Prometheus + Grafana)
- **Ingress**: ALB via AWS Load Balancer Controller + ACM (TLS)
- **GitOps**: ArgoCD (padrão App of Apps)
- **CI/CD**: GitHub Actions com OIDC (sem secret estático)

## Status

Em construção. Ver o board de progresso interno do time.
