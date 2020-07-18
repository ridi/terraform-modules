# iam-group

## Usage
```hcl
module "some_group" {
  source = "github.com/ridi/terraform-modules//aws/iam-group"
  
  name      = "group-name"
  path      = "/developer"
  allow_mfa = true
  force_mfa = true

  policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  policy_inlines = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowReadWriteGroupBucket"
          Principal = "*"
          Effect    = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
          ],
          Resource = [
            "arn:aws:s3:::group-bucket/*"
          ]
        },
      ]
    }),
  ]
}
```

## Input Variables
- `name`: The name of IAM group
- `path`: The path of IAM group
- `policy_arns`: The list of policy arns applied to this group
- `policy_inlines`: The list of inline policies applied to this group
- `allow_mfa`: Whether to allow the group to enable MFA
- `force_mfa`: Whether to force the group to enable MFA

## Output Variables
- `name`: The name of IAM group
- `path`: The path of IAM group
