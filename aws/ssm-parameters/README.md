# ssm-parameters

## Usage
```hcl
module "app_params" {
  source = "github.com/ridi/terraform-modules//aws/ssm-parameters"
  
  path = "/my-service/app"
  
  secret_key  = "mysecret"
  jwt_rsa_pub = file("${path.module}/include/jwt.pub")
}

data "aws_kms_key" "foo" {
  key_id = "alias/my-key"
}

module "rds_params" {
  source = "github.com/ridi/terraform-modules//aws/ssm-parameters"
  
  type   = "SecureString"
  key_id = dat.aws_kms_key.foo.arn
   
  path = "/my-service/db"

  params = {
    "host" = "rds-xxx.yyyy.ap-northeast-2.rds.amazonaws.com"

    "user/root/username" = "root"
    "user/root/password" = "mysecret"

    "user/maxscale/username" = "maxscale"
    "user/maxscale/password" = "mysecret"

    "user/app/username" = "app"
    "user/app/password" = "mysecret"
  }
}
```

## Input Variables
- `path`: The prefix of param names
- `params`: The map variable in form of {$name1 = $value1, $name2 = $value2, ...}
- `type`: The type of value
- `tier`: The tier of the parameter.
- `key_id`: The KMS key id or arn for encrypting a SecureString.
- `overwrite`: Whether overwrites an existing parameter when creates new one
