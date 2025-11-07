{{/*
Container spec that is expanded for the runner container
*/}}
{{- define "runner-mode-empty.runner-container" -}}
{{- if not .Values.runner.container }}
  {{ fail "You must provide a runner container specification in values.runner.container" }}
{{- end }}
{{- $tlsConfig := (default (dict) .Values.githubServerTLS) -}}
name: runner
image: {{ .Values.runner.container.image | default "ghcr.io/actions/runner:latest" }}
command: {{ toJson (default (list "/home/runner/run.sh") .Values.runner.container.command) }}
{{ $extra := omit .Values.runner.container "name" "image" "command" -}}
{{- if not (empty $extra) -}}
{{ toYaml $extra }}
{{- end -}}
{{- end }}