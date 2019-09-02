variable "name" {
  description = "The name of IAM user"
  type        = string
}

variable "path" {
  description = "The path of IAM user"
  type        = string
  default     = "/"
}

variable "policy_arns" {
  description = "The list of policy arns applied to this user"
  type        = list(string)
  default     = []
}

variable "policy_inlines" {
  description = "The list of inline policies applied to this user"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "The list of groups containing this user"
  type        = list(string)
  default     = []
}

variable "allow_mfa" {
  description = "Whether to allow the user to enable MFA"
  type        = bool
  default     = false
}

variable "force_mfa" {
  description = "Whether to force the user to enable MFA"
  type        = bool
  default     = false
}
