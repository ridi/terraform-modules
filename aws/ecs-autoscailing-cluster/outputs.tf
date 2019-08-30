output "ecs_cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2.*.arn[0]
}
