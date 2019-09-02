resource "aws_iam_group" "this" {
  name = var.name
  path = var.path
}

# https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_users-self-manage-mfa-and-creds.html
resource "aws_iam_group_policy" "enable_mfa" {
  count = var.allow_mfa || var.force_mfa ? 1 : 0
  name  = "inline-group-policy-${aws_iam_group.this.name}-enable-mfa"
  group = aws_iam_group.this.name
  policy = templatefile("${path.module}/include/policy_enable_mfa.json.tpl", {
    path = var.path
    name = var.name
  })
}

resource "aws_iam_group_policy" "force_mfa" {
  count  = var.force_mfa ? 1 : 0
  name   = "inline-group-policy-${aws_iam_group.this.name}-force-mfa"
  group  = aws_iam_group.this.name
  policy = file("${path.module}/include/policy_force_mfa.json")
}

resource "aws_iam_group_policy_attachment" "this" {
  count      = length(var.policy_arns)
  policy_arn = var.policy_arns[count.index]
  group      = aws_iam_group.this.id
}

resource "aws_iam_group_policy" "this" {
  count  = length(var.policy_inlines)
  name   = format("iam-grp-policy-%s-%d", var.name, count.index)
  group  = aws_iam_group.this.id
  policy = var.policy_inlines[count.index]
}
