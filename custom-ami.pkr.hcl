packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.7"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami_name" {
  type    = string
  default = "custom-ami"
}

variable "vpc_id" {
  type    = string
}

variable "subnet_id" {
  type    = string
}

variable "ssh_public_key" {
  type    = string
}

locals {
  ssh_username  = "ec2-user"  # SSH username
  instance_type = "t3a.micro" # Instance type
  ssh_timeout   = "20m"        # SSH timeout
  ebs_optimized = false       # EBS optim:ized
  encrypt_boot  = true        # Secure boot 
}

source "amazon-ebs" "custom-ami" {
  ami_name                    = var.ami_name
  instance_type               = local.instance_type
  region                      = var.region
  vpc_id                      = var.vpc_id #"vpc-0de6dcebcb1d1e89e"
  subnet_id                   = var.subnet_id #"subnet-0f178e1e24a05cbba"
  associate_public_ip_address = true
  ssh_username                = local.ssh_username
  ssh_timeout                 = local.ssh_timeout
  ebs_optimized               = local.ebs_optimized
  encrypt_boot                = local.encrypt_boot

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
}

build {
  name = "custom-ami-build"
  sources = [
    "source.amazon-ebs.custom-ami"
  ]

  provisioner "shell" {
    inline = [
      "sudo useradd daveops",
      "sudo usermod -aG wheel daveops",
      "sudo echo 'daveops ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/90-cloud-init-users",
      "sudo mkdir -p /home/daveops/.ssh",
      "sudo touch /home/daveops/.ssh/authorized_keys",
      "sudo echo '${var.ssh_public_key}' | sudo tee -a /home/daveops/.ssh/authorized_keys",
      "sudo chmod 700 /home/daveops/.ssh",
      "sudo chmod 600 /home/daveops/.ssh/authorized_keys",
      "sudo chown -R daveops:daveops /home/daveops/.ssh"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl enable httpd"
    ]
  }
}
