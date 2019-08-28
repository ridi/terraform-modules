locals {
  rule_untagged_1day_expired = {
    rulePriority = 1
    description  = "Remove all untagged images since 1 days"
    selection = {
      tagStatus   = "untagged"
      countType   = "sinceImagePushed"
      countUnit   = "days"
      countNumber = 1
    }
    action = {
      type = "expire"
    }
  }
  rule_commit_tagged_more_than_30 = {
    rulePriority = 2
    description  = "Remove commit-* tagged images more than 30"
    selection = {
      tagStatus     = "tagged"
      tagPrefixList = ["commit-"]
      countType     = "imageCountMoreThan"
      countNumber   = 30
    }
    action = {
      type = "expire"
    }
  }
  rule_ref_tagged_more_than_15 = {
    rulePriority = 3
    description  = "Remove ref-* tagged images more than 15"
    selection = {
      tagStatus     = "tagged"
      tagPrefixList = ["ref-"]
      countType     = "imageCountMoreThan"
      countNumber   = 15
    }
    action = {
      type = "expire"
    }
  }
  rule_tag_tagged_more_than_10 = {
    rulePriority = 4
    description  = "Remove tag-* tagged images more than 10"
    selection = {
      tagStatus     = "tagged"
      tagPrefixList = ["tag-"]
      countType     = "imageCountMoreThan"
      countNumber   = 10
    }
    action = {
      type = "expire"
    }
  }
}

resource "aws_ecr_repository" "this" {
  name = var.repo_name
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      local.rule_untagged_1day_expired,
      local.rule_commit_tagged_more_than_30,
      local.rule_ref_tagged_more_than_15,
      local.rule_tag_tagged_more_than_10,
    ]
  })
}
