variable "app_name" {
  description = "App name"
  type        = string
  default     = "2048-game"
}

variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}

variable "app_count" {
  description = "The number of instances to deploy"
  type        = number
  default     = 3
}

variable "resources" {
  description = "The resource to assign to the application."
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 500,
    memory = 256
  }
}

variable "docker_artifact" {
  type = object({
    image = string
    tag   = string
  })
  default = {
      image = "alexwhen/docker-2048"
      tag   = "latest"
  }
}
