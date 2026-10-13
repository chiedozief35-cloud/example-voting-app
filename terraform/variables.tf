variable "admin_cidr" {
  description = "Your public IPv4 address with a /32 suffix."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && endswith(var.admin_cidr, "/32")
    error_message = "Use one IPv4 address followed by /32."
  }
}

variable "ami_id" {
  description = "Pinned Ubuntu 24.04 AMD64 AMI in eu-north-1."
  type        = string
}

variable "instance_type" {
  description = "Instance type verified as eligible for this Free-plan deployment."
  type        = string

  validation {
    condition     = var.instance_type == "m7i-flex.large"
    error_message = "This configuration currently expects m7i-flex.large."
  }
}

variable "subnet_id" {
  description = "Existing default subnet for both nodes."
  type        = string
  default     = "subnet-0dc5671f7e9dcfacc"
}

variable "ssh_public_key_path" {
  description = "Public SSH key on your Mac."
  type        = string
  default     = "~/.ssh/tsacademy-capstone.pub"
}

variable "k3s_version" {
  description = "Pinned K3s version for both nodes."
  type        = string
  default     = "v1.37.1+k3s1"
}
