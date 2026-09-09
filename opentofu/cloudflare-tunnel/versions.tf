terraform {
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.52.9, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.0, < 4.0.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
