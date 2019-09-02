resource "aws_iam_user" "this" {
  name = var.name
  path = var.path
}

resource "aws_iam_user_policy_attachment" "this" {
  count      = length(var.policy_arns)
  user       = aws_iam_user.this.name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_iam_user_policy" "this" {
  count  = length(var.policy_inlines)
  name   = format("inline-user-policy-%s-%d", aws_iam_user.this.name, count.index)
  user   = aws_iam_user.this.name
  policy = var.policy_inlines[count.index]
}

# https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_users-self-manage-mfa-and-creds.html
resource "aws_iam_user_policy" "enable_mfa" {
  count = var.allow_mfa || var.force_mfa ? 1 : 0
  name  = "inline-user-policy-${aws_iam_user.this.name}-enable-mfa"
  user  = aws_iam_user.this.name
  policy = templatefile("${path.module}/include/policy_enable_mfa.json.tpl", {
    path = var.path
    name = var.name
  })
}

resource "aws_iam_user_policy" "force_mfa" {
  count  = var.force_mfa ? 1 : 0
  name   = "inline-policy-${aws_iam_user.this.name}-force-mfa"
  user   = aws_iam_user.this.name
  policy = file("${path.module}/include/policy_force_mfa.json")
}

resource "aws_iam_user_group_membership" "this" {
  count  = length(var.groups)
  user   = aws_iam_user.this.name
  groups = var.groups
}
