variable "my_ip" {
  description = "Adresse IP publique autorisee en SSH"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}
