# GitOps — App of Apps (ArgoCD)

Camada 2 do projeto (workloads). Tudo aqui é declarativo: o ArgoCD lê este
diretório do Git e sincroniza o cluster para o estado descrito. É o que permite
reconstruir o cluster após um `terraform destroy` sem perder configuração.

## Estrutura

```
gitops/
  bootstrap/
    root-app.yaml          # Application RAIZ (App of Apps) — aplicada 1x no bootstrap
  apps/                    # Applications filhas (descobertas pela root-app)
    external-dns.yaml           # wave 0 — registros DNS no Route53
    kube-prometheus-stack.yaml  # wave 0 — Prometheus + Grafana + Alertmanager
    picpay-app.yaml             # wave 1 — nossa aplicação
```

> O **AWS Load Balancer Controller** NÃO é uma Application do ArgoCD. Ele é
> instalado via **Terraform** (Helm provider) no `apply` inicial (Camada 1),
> por praticidade: é pré-requisito de qualquer Ingress, então tê-lo pronto já no
> bootstrap evita o problema do "ovo e galinha" com o GitOps. A permissão
> continua vindo do EKS Pod Identity (contrato de SA abaixo permanece válido).

## Como funciona o App of Apps

Aplica-se **apenas** a `root-app` (o Terraform faz isso após instalar o ArgoCD).
A root-app aponta para `apps/`, onde cada arquivo é uma Application. O ArgoCD
cria e passa a gerenciar cada uma. Mudou algo no Git → o ArgoCD reconcilia.

## Ordem de instalação (sync-waves)

A anotação `argocd.argoproj.io/sync-wave` ordena a subida, respeitando dependências:

O AWS Load Balancer Controller já existe (instalado pelo Terraform), então o
ALB é atendido assim que a app cria o Ingress.

| Wave | Application | Por quê nesta ordem |
|---|---|---|
| 0 | external-dns | Sobe cedo; passa a agir quando houver hosted zone (Fase 7) |
| 0 | kube-prometheus-stack | Instala o CRD `ServiceMonitor` antes de a app criar o dela |
| 1 | picpay-app | Já encontra o CRD ServiceMonitor e o LB Controller (do Terraform) prontos |

## Contrato com o EKS Pod Identity (crítico)

Os controllers recebem permissão AWS via **EKS Pod Identity** (ver `docs/DECISOES.md`
D18), não IRSA. O Terraform (`modules/pod-identity`) associou uma IAM role a um
par **(namespace, serviceAccount)**. Para a credencial chegar na pod, o Helm de
cada controller **precisa criar a service account com exatamente esse nome**:

| Controller | namespace | serviceAccount |
|---|---|---|
| AWS Load Balancer Controller | `kube-system` | `aws-load-balancer-controller` |
| ExternalDNS | `external-dns` | `external-dns` |

Para o ExternalDNS isso está nos `values` da Application (`serviceAccount.create: true`
+ `serviceAccount.name: <nome>`). Para o **LB Controller**, como ele é instalado
pelo Terraform, esse mesmo contrato de SA deve ser configurado nos `values` do
Helm **no Terraform**. **Não** anotar a SA com `eks.amazonaws.com/role-arn` (isso
é de IRSA; Pod Identity dispensa). Se os nomes divergirem, o controller sobe sem
permissão e falha silenciosamente (ex.: o ALB nunca aparece).

## Versões dos charts de terceiros

Os campos `targetRevision` das Applications de terceiros estão com **versões
placeholder** (comentadas no arquivo). Antes do bootstrap, confirme a versão
estável atual e fixe-a (reprodutibilidade):

```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo external-dns/external-dns
helm search repo prometheus-community/kube-prometheus-stack
```

(A versão do chart do AWS Load Balancer Controller é fixada no **Terraform**, não aqui.)

Fixar uma versão exata evita que um `sync` futuro puxe uma versão nova e quebre algo.

## A app (picpay-app) e as duas esteiras

`picpay-app.yaml` é a única Application que aponta para **este** repo (chart em
`helm/picpay-app`). A tag da imagem (`image.tag`) é **bumpada pelo CI** do repo
da app (`picpay-app-prz`) a cada push: o CI builda/publica no ECR e commita a
nova tag aqui. O ArgoCD detecta o commit e faz o deploy. CI (repo da app) e CD
(ArgoCD) se encontram neste `values`.

## Bootstrap (resumo)

1. `terraform apply` cria o cluster, instala o **AWS Load Balancer Controller** e
   o **ArgoCD** (ambos via Helm no Terraform) e aplica `bootstrap/root-app.yaml`.
2. A root-app descobre `apps/` e cria as Applications filhas.
3. ArgoCD sincroniza nas waves 0 → 1.
4. App sobe com Ingress → o LB Controller (já instalado) cria o ALB → (Fase 7)
   ExternalDNS cria o DNS e o ACM dá o HTTPS.
