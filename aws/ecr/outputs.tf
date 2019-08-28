output "repo_url" {
  description = "The url of ECR repository"
  value       = aws_ecr_repository.this.repository_url
}
