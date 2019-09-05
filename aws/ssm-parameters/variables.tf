variable "path" {
  description = "The prefix of param names"
  type        = string
  default     = ""
}

variable "params" {
  description = "The map variable in form of {$name1 = $value1, $name2 = $value2, ...}"
  type        = map(string)
}

variable "type" {
  description = "The type of value"
  type        = string
  default     = "String"
}

variable "tier" {
  description = "The tier of the parameter."
  type        = string
  default     = "Standard"
}

variable "key_id" {
  description = "The KMS key id or arn for encrypting a SecureString."
  type        = string
  default     = null
}

variable "overwrite" {
  description = "Whether overwrites an existing parameter or not"
  type        = bool
  default     = false
}
