{{/*
Chart name truncated to 63 chars.
*/}}
{{- define "inhouse-ai.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name (release-chart).
*/}}
{{- define "inhouse-ai.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "inhouse-ai.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Ollama labels.
*/}}
{{- define "inhouse-ai.ollama.labels" -}}
{{ include "inhouse-ai.labels" . }}
app.kubernetes.io/name: ollama
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Ollama selector labels.
*/}}
{{- define "inhouse-ai.ollama.selectorLabels" -}}
app.kubernetes.io/name: ollama
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Open WebUI labels.
*/}}
{{- define "inhouse-ai.openwebui.labels" -}}
{{ include "inhouse-ai.labels" . }}
app.kubernetes.io/name: open-webui
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Open WebUI selector labels.
*/}}
{{- define "inhouse-ai.openwebui.selectorLabels" -}}
app.kubernetes.io/name: open-webui
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
LiteLLM labels.
*/}}
{{- define "inhouse-ai.litellm.labels" -}}
{{ include "inhouse-ai.labels" . }}
app.kubernetes.io/name: litellm
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: proxy
{{- end }}

{{/*
LiteLLM selector labels.
*/}}
{{- define "inhouse-ai.litellm.selectorLabels" -}}
app.kubernetes.io/name: litellm
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
