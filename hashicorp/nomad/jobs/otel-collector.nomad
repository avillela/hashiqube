job "otel-collector-gateway" {

  datacenters = ["dc1"]

  group "svc" {
    count = 1

    vault {
      policies  = ["otel"]
    }

    network {

      port "otlp-grpc" {
        to = 4317
      }

      port "otlp-http" {
        to = 4318
      }

      port "metrics" {
        to = 8888
      }

      # Receivers
      port "prom" {
        to = 9090
      }

    }

    service {
      tags = [
        "traefik.http.routers.collector.rule=Host(`otel-collector-http.localhost`)",
        "traefik.http.routers.collector.entrypoints=web",
        "traefik.http.routers.collector.tls=false",
        "traefik.enable=true",
      ]

      port = "otlp-http"

    }


    service {
      name = "otel-collector-hc"
      port = "prom"
      tags = ["prom"]
    }

    service {
      name = "otel-agent-hc"
      port = "metrics"
      tags = ["metrics"]
    }

    task "svc" {
      driver = "docker"

      config {
        image = "otel/opentelemetry-collector-contrib:0.50.0"
        force_pull = true

        entrypoint = [
          "/otelcol-contrib",
          "--config=local/config/otel-collector-config.yaml",
        ]
        ports = [
          "metrics",
          "prom",
          "otlp-grpc",
          "otlp-http"
        ]
      }


      resources {
        cpu    = 100
        memory = 512
      }

      template {
        data   = <<EOF

receivers:
  otlp:
    protocols:
      grpc:
      http:
        endpoint: "0.0.0.0:4318"

processors:
  batch:
    timeout: 10s
  memory_limiter:
    # 75% of maximum memory up to 4G
    limit_mib: 1536
    # 25% of limit up to 2G
    spike_limit_mib: 512
    check_interval: 5s

exporters:
  logging:
    logLevel: debug

  jaeger:
    endpoint: jaeger-proto.localhost:7233
    tls:
      insecure: true    

  otlp/hc:
    endpoint: "api.honeycomb.io:443"
    headers: 
      "x-honeycomb-team": "{{ with secret "kv/data/otel/o11y/honeycomb" }}{{ .Data.data.api_key }}{{ end }}"
      "x-honeycomb-dataset": "hny-otel-collector"
  otlp/ls:
    endpoint: ingest.lightstep.com:443
    headers: 
      "lightstep-access-token": "{{ with secret "kv/data/otel/o11y/lightstep" }}{{ .Data.data.api_key }}{{ end }}"

  datadog:
    service: dd_trace_example
    tags:
      - env:local_dev_env
    api:
      key: "{{ with secret "kv/data/otel/o11y/datadog" }}{{ .Data.data.api_key }}{{ end }}"
      site: datadoghq.com

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [logging, otlp/ls, otlp/hc, datadog, jaeger]
EOF
        destination = "local/config/otel-collector-config.yaml"
      }
    }
  }
}