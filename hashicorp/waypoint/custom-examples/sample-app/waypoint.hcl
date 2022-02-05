project = "sample-proj"

variable "game_2048_docker" {
  type = object({
    image = string
    tag   = string
  })
  default = {
      image = "alexwhen/docker-2048"
      tag   = "latest"
  }
}

variable "otel_collector_docker" {
  type = object({
    image = string
    tag   = string
  })
  default = {
      image = "otel/opentelemetry-collector-contrib"
      tag   = "0.40.0"
  }
}


app "2048-game" {

    build {
        use "docker-pull" {
            image = var.game_2048_docker.image
            tag = var.game_2048_docker.tag
        }        
    }

    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/2048-game.nomad.tpl", {
                docker_artifact = "${var.game_2048_docker}",
            })
        }
    }

}

app "otel-collector" {

    build {
        use "docker-pull" {
            image = var.otel_collector_docker.image
            tag = var.otel_collector_docker.tag
        }        
    }

    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/otel-collector.nomad.tpl", {
                docker_artifact = "${var.otel_collector_docker}",
            })
        }
    }
}
