provider "aws" {
  region = "ap-south-1"
}

variable "ami_id" {
  description = "Amazon Machine Image (AMI) ID for the EC2 instance"
  default     = "ami-023a307f3d27ea427"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key name"
  default     = "mosip-qa"
}

# Lookup existing security group by name
data "aws_security_group" "existing_perf_vm_sg" {
  filter {
    name   = "group-name"
    values = ["mosip-k8s-performance-vm"]
  }
  # Avoid failing if the security group doesn't exist
  ignore_errors = true
}

resource "aws_security_group" "perf_vm_sg" {
  count       = (try(data.aws_security_group.existing_perf_vm_sg.id, "") == "") ? 1 : 0
  name        = "mosip-k8s-performance-vm"
  description = "Allow necessary access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5900
    to_port     = 5900
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    t
