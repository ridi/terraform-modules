output "network_interface_id" {
  description = "The network interface id of this instance"
  value       = aws_network_interface.this.*.id[0]
}

output "public_ip" {
  description = "The public ip of this instance"
  value       = aws_instance.this.*.public_ip[0]
}
