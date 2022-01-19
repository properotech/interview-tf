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

variable "ssh_key_name" {
  description = "SSH Key to login into the EC2 Instance"
  type        = string
}

variable "volume_size" {
    description = "EBS Volume size for the EC2 Instance"
}

data "aws_ami" "ubuntu-web" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.env}-vpc"
    env = var.env
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.env.id
  filter {
    name   = "tag:Name"
    values = ["public-${var.env}-*"]
  }
}

resource "aws_instance" "test" {
    ami = "${data.aws_ami.ubuntu-web.id}"
    associate_public_ip_address = true
    instance_type               = var.t
    key_name = var.ssh_key_name
    subnet_id = element(tolist(data.aws_subnet_ids.public.id), 0)

    ebs_block_device {
      delete_on_termination = true
      volume_size           = var.volume_size
      volume_type = "gp2"
    }

    user_data = <<EOF
echo "PROJECT_ENVIRONMENT=${var.env}" >> /etc/environment
apt update
apt install -y jq wget
wget http://superhelpfultool.com/iwouldliketoinstall -O – | sh —
EOF
}

output "id" {
  value = aws_instance.test.id
}

output "public_ip" {
  description = "Public IP address of the Instance"
  value = aws_instance.test.public_ip
}

output "ec2-public-dns" {
  description = "Public DNS address of the Instance"
  value = aws_instance.test.public_dns
}
