variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "whitelist_ip" {
  description = "IP to whitelist for SSH"
  type        = string
}

variable "db_password" {
  description = "Cloud SQL database password"
  type        = string
  sensitive   = true
}
