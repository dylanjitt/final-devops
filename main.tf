provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "chatty_llama_key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "chatty_llama_key.pem"
}
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "chatty_llama" {
  ami           = "ami-0e2c8caa4b6378d8c" # Ubuntu 22.04 AMI for us-east-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name

  root_block_device {
    volume_size = 20
  }

  user_data = <<-EOT
              #!/bin/bash
              sudo apt update -y
              curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
              source $HOME/.cargo/env
              sudo apt install -y git python3-pip python3.12-venv
              git clone https://github.com/dylanjitt/chatty-llama.git
              sudo chown -R ubuntu:ubuntu chatty-llama/
              cd chatty-llama/
              make install-huggingface-cli
              python3 -m venv venv
              source venv/bin/activate
              export HF_TOKEN=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
              make download-model
              make chatty-llama
            EOT
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "chatty-llama-ec2"
  }
}

output "instance_ip" {
  value = aws_instance.chatty_llama.public_ip
}

output "key_file" {
  value = local_file.private_key.filename
}


