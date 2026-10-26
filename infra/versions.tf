terraform {
  required_version = ">= 1.17.0, < 1.18.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }

  backend "local" {}
}

provider "docker" {}
