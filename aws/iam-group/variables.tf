variable "name" {
  description = "The name of IAM group"
  type        = string
}

variable "path" {
  description = "The path of IAM group"
  type        = string
  default     = "/"
}

variable "policy_arns" {
  description = "The list of policy arns applied to this group"
  type        = list(string)
  default     = []
}

variable "policy_inlines" {
  description = "The list of inline policies applied to this group"
  type        = list(string)
  default     = []
}

variable "allow_mfa" {
  description = "Whether to allow the group to enable MFA"
  type        = bool
  default     = false
}

variable "force_mfa" {
  description = "Whether to force the group to enable MFA"
  type        = bool
  default     = false
}
