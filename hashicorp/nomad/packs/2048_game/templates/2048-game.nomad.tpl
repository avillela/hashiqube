job "[[ .game_2048.app_name ]]" {
  type        = "service"
  region      = "[[ .game_2048.region ]]"
  datacenters = [ [[ range $idx, $dc := .game_2048.datacenters ]][[if $idx]],[[end]][[ $dc | quote ]][[ end ]] ]


  group "game" {
    count = [[ .game_2048.app_count ]]

    network {
      mode = "bridge"

      port "http" {
        to = 80
      }
    }

    service {
      tags = [
        "traefik.http.routers.[[ .game_2048.app_name ]].rule=Host(`[[ .game_2048.app_name ]].localhost`)",
        "traefik.http.routers.[[ .game_2048.app_name ]].entrypoints=web",
        "traefik.http.routers.[[ .game_2048.app_name ]].tls=false",
        "traefik.enable=true",
      ]

      port = "http"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }
 
    task "2048" {
      driver = "docker"
 
      config {
        image = "[[ .game_2048.docker_artifact.image ]]:[[ .game_2048.docker_artifact.tag ]]"

        ports = ["http"]
      }

      resources {
        cpu    = [[ .game_2048.resources.cpu ]]
        memory = [[ .game_2048.resources.memory ]]
      }
    }
  }
}