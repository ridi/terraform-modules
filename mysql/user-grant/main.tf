locals {
  user_host = split("@", var.user)
  user      = local.user_host[0]
  host      = length(local.user_host) < 2 ? "localhost" : local.user_host[1]
  grants = flatten([
    for db_name, db_priv in var.grants : [
      for table_name, table_priv in db_priv : {
        database   = db_name
        table      = table_name
        privileges = table_priv
      }
    ]
  ])
}

resource "mysql_user" "this" {
  user               = local.user
  host               = local.host
  plaintext_password = var.password
}

resource "mysql_grant" "this" {
  count = length(local.grants)

  user       = mysql_user.this.user
  host       = mysql_user.this.host
  database   = local.grants[count.index].database
  table      = local.grants[count.index].table
  privileges = local.grants[count.index].privileges
}
