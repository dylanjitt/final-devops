provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "macgod_key"
  public_key = file("macgod.pub")
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

  ingress {
    from_port   = 80
    to_port     = 80
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

variable "huggingface_token" {
  description = "HuggingFace API Token"
  type        = string
  sensitive   = true
}



resource "aws_instance" "chatty_llama" {
  ami           = "ami-005fc0f236362e99f" # Amazon Linux AMI for us-east-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name

  root_block_device {
    volume_size = 20
  }

  user_data = templatefile("userdata.sh", {
    huggingface_token = var.huggingface_token
  })

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "chatty-llama-ec2"
  }
}

output "instance_ip" {
  value = aws_instance.chatty_llama.public_ip
}




