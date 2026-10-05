# Terraform — Camada 1 (Infraestrutura) · PicPay Challenge

Provisiona, de forma modular, a infraestrutura base do desafio EKS na região
`us-east-2`: VPC, cluster EKS com node group SPOT, repositório ECR e roles IRSA
para os controllers do cluster.

> A Camada 2 (AWS Load Balancer Controller, ExternalDNS, cert-manager,
> observabilidade e a aplicação) é instalada via GitOps (ArgoCD), não por este
> Terraform.

## Módulos

| Módulo | O que faz |
|---|---|
| `modules/vpc` | VPC `10.0.0.0/16` em 3 AZs, subnets pública/privada, NAT único (custo), tags de discovery do EKS/ELB. Usa `terraform-aws-modules/vpc/aws ~> 5.0`. |
| `modules/eks` | Control plane EKS (`~> 20.0`), logging de auditoria, IRSA, addons (coredns, kube-proxy, vpc-cni, ebs-csi) e node group **SPOT** multi-AZ nas subnets privadas. |
| `modules/ecr` | Repositório ECR privado da aplicação: scan on push, tags imutáveis, criptografia AES256 e lifecycle policy (limpa imagens antigas/não-tageadas). |
| `modules/iam-irsa` | Roles IAM via OIDC/IRSA para o AWS Load Balancer Controller e o ExternalDNS. Usa o submódulo oficial `iam-role-for-service-accounts-eks`. |

## Ordem de composição

A raiz (`main.tf`) instancia os módulos na ordem de dependência:

1. `vpc`
2. `eks` (recebe `vpc_id` e `private_subnets` da VPC)
3. `ecr` (independente)
4. `iam_irsa` (recebe `oidc_provider_arn` e `cluster_oidc_issuer_url` do EKS)

## Variáveis principais

| Variável | Default | Descrição |
|---|---|---|
| `project` | `picpay-challenge` | Prefixo de nomes/tags. |
| `region` | `us-east-2` | Região fixa do projeto. |
| `environment` | `dev` | Ambiente lógico. |
| `cluster_version` | `1.36` | Versão do Kubernetes (N-1 por estabilidade). |
| `node_instance_types` | `t3.medium, t3a.medium, t3.large, t3a.large` | Tipos SPOT diversificados. |
| `node_min_size` / `node_desired_size` / `node_max_size` | `2` / `2` / `4` | Dimensionamento do node group SPOT. |
| `ecr_repository_name` | `picpay-challenge-app` | Nome do repositório ECR. |

O nome do cluster é derivado como `${project}-${environment}` → `picpay-challenge-dev`.

## Backend e estado

Backend remoto S3 (`backend.tf`): bucket `picpay-challenge-tfstate-390736326016`,
lock nativo S3 (`use_lockfile = true`, **sem DynamoDB** — decisão D13), state
criptografado.

## Configurar o kubeconfig (após o apply)

```sh
aws eks update-kubeconfig --region us-east-2 --name picpay-challenge-dev
```

O output `update_kubeconfig_command` imprime este comando já preenchido.

## Notas de custo

- Control plane EKS: ~US$73/mês fixo.
- NAT gateway único (em vez de um por AZ) para reduzir custo em dev.
- Node group **SPOT** com tipos diversificados: menor custo e menor risco de
  interrupção simultânea.
- Lifecycle policy no ECR limpa imagens antigas, controlando o storage.

## ⚠️ Aprovação obrigatória para ações na AWS

`terraform apply` e `terraform destroy` **exigem aprovação explícita do usuário**.
Este diretório foi preparado apenas com a configuração; nenhum recurso foi criado.

## Estado da verificação

- `terraform fmt -recursive -check`: **limpo** (sem diffs de formatação).
- Revisão manual das referências entre módulos: **ok** — os outputs de cada
  módulo batem com os inputs do próximo (`vpc → eks → iam-irsa`, `ecr` independente).
- `terraform init` / `terraform validate`: **não executados** — por decisão do
  usuário, nada é validado com Terraform nesta etapa (evita contatar o registry/
  backend). A validação completa fica pendente para quando o usuário autorizar.
