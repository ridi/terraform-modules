variable "user" {
  description = "The MySQL account in form of YOUR_ID@HOST. if no '@' character exists, use 'losthost' as default"
  type        = string
}

variable "password" {
  description = "The password of user"
  type        = string
}

variable "grants" {
  description = "The grants map for each databases and tables. { database: { table: [PRIVILEGE_TYPE, ...], ... }, ... }"
  type        = map(map(list(string)))
}
