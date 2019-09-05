resource "aws_ssm_parameter" "this" {
  for_each = var.params

  type      = var.type
  key_id    = var.key_id
  tier      = var.tier
  overwrite = var.overwrite

  name  = length(regexall("^/.*", each.key)) > 0 ? "${var.path}${each.key}" : "${var.path}/${each.key}"
  value = each.value
}
