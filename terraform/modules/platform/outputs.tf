output "argocd_namespace" {
  description = "Namespace onde o ArgoCD foi instalado."
  value       = helm_release.argocd.namespace
}

output "argocd_initial_admin_password_command" {
  description = "Comando para obter a senha inicial do admin do ArgoCD (secret gerado no bootstrap)."
  value       = "kubectl -n ${helm_release.argocd.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_ingress_hint" {
  description = "Como descobrir o hostname do ALB do ArgoCD após o provisionamento (leva alguns minutos)."
  value       = "kubectl -n ${helm_release.argocd.namespace} get ingress argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
