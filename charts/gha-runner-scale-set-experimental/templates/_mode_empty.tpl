{{/*
Container spec that is expanded for the runner container
*/}}
{{- define "runner-mode-empty.runner-container" -}}
{{- if not .Values.runner.container }}
  {{ fail "You must provide a runner container specification in values.runner.container" }}
{{- end }}
{{- $tlsConfig := (default (dict) .Values.githubServerTLS) -}}
{{- $tlsMountPath := (index $tlsConfig "runnerMountPath" | default "") -}}
{{- $tlsCertKey := "" -}}
{{- if $tlsMountPath -}}
  {{- $tlsCertKey = required "githubServerTLS.certificateFrom.configMapKeyRef.key is required when githubServerTLS.runnerMountPath is set" (index $tlsConfig "certificateFrom" "configMapKeyRef" "key") -}}
{{- end -}}
name: runner
image: {{ .Values.runner.container.image | default "ghcr.io/actions/runner:latest" }}
command: {{ toJson (default (list "/home/runner/run.sh") .Values.runner.container.command) }}

{{/* Merge/add TLS env vars without duplicating user-defined ones */}}
{{ $setNodeExtraCaCerts := false }}
{{ $setRunnerUpdateCaCerts := false }}
{{ if $tlsMountPath }}
  {{ $setNodeExtraCaCerts = true }}
  {{ $setRunnerUpdateCaCerts = true }}
  {{ with .Values.runner.container.env }}
    {{ range . }}
      {{ if and (kindIs "map" .) (eq ((index . "name") | default "") "NODE_EXTRA_CA_CERTS") }}
        {{ $setNodeExtraCaCerts = false }}
      {{ end }}
      {{ if and (kindIs "map" .) (eq ((index . "name") | default "") "RUNNER_UPDATE_CA_CERTS") }}
        {{ $setRunnerUpdateCaCerts = false }}
      {{ end }}
    {{ end }}
  {{ end }}
{{ end }}
{{ if or .Values.runner.container.env $setNodeExtraCaCerts $setRunnerUpdateCaCerts }}
env:
  {{- with .Values.runner.container.env }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- if $setNodeExtraCaCerts }}
  - name: NODE_EXTRA_CA_CERTS
    value: {{ printf "%s/%s" (trimSuffix "/" $tlsMountPath) $tlsCertKey | quote }}
  {{- end }}
  {{- if $setRunnerUpdateCaCerts }}
  - name: RUNNER_UPDATE_CA_CERTS
    value: "1"
  {{- end }}
{{ end }}

{{/* Merge/add TLS volumeMount without duplicating user-defined ones */}}
{{ $setTLSVolumeMount := false }}
{{ if $tlsMountPath }}
  {{ $setTLSVolumeMount = true }}
  {{ with .Values.runner.container.volumeMounts }}
    {{ range . }}
      {{ if and (kindIs "map" .) (eq ((index . "name") | default "") "github-server-tls-cert") }}
        {{ $setTLSVolumeMount = false }}
      {{ end }}
    {{ end }}
  {{ end }}
{{ end }}
{{ if or .Values.runner.container.volumeMounts $setTLSVolumeMount }}
volumeMounts:
  {{- with .Values.runner.container.volumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- if $setTLSVolumeMount }}
  - name: github-server-tls-cert
    mountPath: {{ $tlsMountPath | quote }}
    readOnly: true
  {{- end }}
{{ end }}

{{ $extra := omit .Values.runner.container "name" "image" "command" "env" "volumeMounts" -}}
{{- if not (empty $extra) -}}
{{ toYaml $extra }}
{{- end -}}
{{- end }}