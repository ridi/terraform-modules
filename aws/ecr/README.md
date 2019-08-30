# ecr

## Usage
```hcl
module "foo" {
  source = "github.com/ridi/terraform-modules//aws/ecr"
  
  repo_name = "my-awesome-repo"
}
```

## Input Variables
- `repo_name` - Name of ECR repository

## Outputs
- `repo_url` - The url of ECR repository
