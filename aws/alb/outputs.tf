output "alb_target_group_arns" {
  value = { for tg in aws_alb_target_group.this :
    tg.name => tg.arn
  }
}

output "alb_dns_name" {
  value = aws_alb.this.dns_name
}
