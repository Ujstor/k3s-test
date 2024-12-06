module "ssh_key_bootstrap" {
  source = "github.com/Ujstor/terraform-hetzner-modules//modules/ssh_key?ref=v0.0.3"

  ssh_key_name = "bootstrap_key"
  ssh_key_path = ".ssh"
}

# module "ssh_key_ansible" {
#   source = "github.com/Ujstor/terraform-hetzner-modules//modules/ssh_key?ref=v0.0.3"
#
#   ssh_key_name = "ansible_key"
#   ssh_key_path = ".ssh"
# }

# module "ssh_key_foo" {
#   source = "github.com/Ujstor/terraform-hetzner-modules//modules/ssh_key?ref=v0.0.3"
#
#   ssh_key_name = "foo_key"
#   ssh_key_path = ".ssh"
# }
#
# module "ssh_key_bar" {
#   source = "github.com/Ujstor/terraform-hetzner-modules//modules/ssh_key?ref=v0.0.3"
#
#   ssh_key_name = "bar_key"
#   ssh_key_path = ".ssh"
# }

module "bootstrap_server" {
  source = "github.com/Ujstor/terraform-hetzner-modules//modules/server?ref=v0.0.3"

  server_config = {
    bootstrap = {
      location     = "hel1"
      server_type  = "cx22"
      ipv6_enabled = false
    }
  }

  os_type = "ubuntu-24.04"

  hcloud_ssh_key_id = [module.ssh_key_bootstrap.hcloud_ssh_key_id]

  depends_on = [module.ssh_key_bootstrap]
}

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.37"
    }
  }
  required_version = ">= 1.0.0, < 2.0.0"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
  type        = string
}

output "server_info" {
  value = module.bootstrap_server.server_info
}

module "cloudflare_record" {
  source = "github.com/Ujstor/terraform-hetzner-modules//modules/network/cloudflare_record?ref=v0.0.6"

  cloudflare_record = {
    argo_cd = {
      zone_id = var.cloudflare_zone_id
      name    = "argocd.k3s.test"
      content = module.bootstrap_server.server_info.bootstrap.ip
      type    = "A"
      ttl     = 60
      proxied = false
    }
    todo = {
      zone_id = var.cloudflare_zone_id
      name    = "todo.test"
      content = module.bootstrap_server.server_info.bootstrap.ip
      type    = "A"
      ttl     = 60
      proxied = false
    }
  }
}
