{{/*
Helpers padrão do chart. Centralizam nomes e labels para manter consistência
entre todos os manifestos (Deployment, Service, PDB, etc.).
*/}}

{{/* Nome base do chart (pode ser sobrescrito por nameOverride). */}}
{{- define "picpay-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Nome "fullname" (prefixado pelo release), limitado a 63 chars (limite de nomes
de recursos no Kubernetes). Se o release já contém o nome do chart, evita
duplicar (ex.: release "picpay-app" -> "picpay-app", não "picpay-app-picpay-app").
*/}}
{{- define "picpay-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Chart name + version, para a label helm.sh/chart. */}}
{{- define "picpay-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comuns: aplicadas em todos os recursos. Seguem as recomendações de
labels do Kubernetes (app.kubernetes.io/*).
*/}}
{{- define "picpay-app.labels" -}}
helm.sh/chart: {{ include "picpay-app.chart" . }}
{{ include "picpay-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels: subconjunto IMUTÁVEL usado em selectors (Deployment, Service,
PDB). Nunca inclua aqui labels que mudam (ex.: version), senão quebra o selector.
*/}}
{{- define "picpay-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "picpay-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Nome da service account a usar. */}}
{{- define "picpay-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "picpay-app.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
