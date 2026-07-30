data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "ALS_keypair_depcloudsecu"
  public_key = file("${path.module}/ansible-key.pub")
}

resource "aws_instance" "web" {
  ami                    = "ami-0e207c18bb303cc68"
  key_name               = aws_key_pair.deployer.key_name
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }
  user_data = <<-USERDATA
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx
              USERDATA
  tags = {
    Name = "tp2-web-server-ALS"
  }
}
