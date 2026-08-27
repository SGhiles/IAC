locals {
  prefix = "${var.username}-${var.environment}"
}

# AMI Amazon Linux 2023 la plus recente, automatiquement (pas d'ID en dur)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.prefix}-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Petit serveur web minimal pour verifier l'accessibilite HTTP
  user_data = <<-EOF2
    #!/bin/bash
    dnf install -y nginx
    systemctl stop firewalld
    systemctl disable firewalld
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Serveur web - ${local.prefix}</h1>" > /usr/share/nginx/html/index.html
  EOF2

  tags = {
    Name = "${local.prefix}-web"
  }
}
