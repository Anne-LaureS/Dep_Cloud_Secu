output "instance_public_ip" {
  description = "IP publique de l'instance web"
  value       = aws_instance.web.public_ip
}
