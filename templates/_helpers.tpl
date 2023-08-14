{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
*/}}
{{- define "names.namespace" -}}
{{- if and .Values.namespace.create .Values.namespaceOverride -}}
{{- .Values.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
 Create the name of the service account to use
 */}}
{{- define "names.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
The below sample usage of the defined template returns the proper image name
{{ include "images.image" ( dict "imageRoot" .Values.path.to.the.image "global" $) }}
*/}}
{{- define "images.image" -}}
{{- $registryName := .imageRoot.registry | default "" -}}
{{- $repositoryName := .imageRoot.repository | default "" -}}
{{- $imageName := required "imageRoot.name is required" .imageRoot.name -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | default "" | toString -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName -}}
  {{- $registryName = printf "%s/" $registryName  -}}
{{- end -}}
{{- if $repositoryName -}}
  {{- $repositoryName = printf "%s/" $repositoryName -}}
{{- end -}}
{{- if and $imageName $termination -}}
{{- printf "%s%s%s%s%s" $registryName $repositoryName $imageName $separator $termination -}}
{{- else if $imageName -}}
{{- printf "%s%s%s" $registryName $repositoryName $imageName -}}
{{- end -}}
{{- end -}}
