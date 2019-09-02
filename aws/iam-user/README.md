# iam-user

## Usage
```hcl
module "some_user" {
  source = "github.com/ridi/terraform-modules//aws/iam-user"
  
  name      = "my-name"
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
          Sid       = "AllowReadWriteMyBucket"
          Principal = "*"
          Effect    = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject"
          ],
          Resource = [
            "arn:aws:s3:::my-bucket/*"
          ]
        },
      ]
    }),
  ]

  groups = [
    "developer",
  ]
}
```

## Input Variables
- `name`: The name of IAM user
- `path`: The path of IAM user
- `policy_arns`: The list of policy arns applied to this user
- `policy_inlines`: The list of inline policies applied to this user
- `groups`: The list of groups containing this user
- `allow_mfa`: Whether to allow the user to enable MFA
- `force_mfa`: Whether to force the user to enable MFA

## Output Variables
- `name`: The name of IAM user
- `path`: The path of IAM user
