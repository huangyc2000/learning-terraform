#variable "instance_type" {
#  description = "Type of EC2 instance to provision"
#  default     = "t3.nano"
#}

/*
variable "webserver_ami" {
  type = string
  default = "ami-abc123"
}


resource "aws_instance" "web" {
  ami = var.webserver_ami
  ...
}
 run as:
 $ terraform apply -f -var="webserver_ami=ami-12345"
 */

 variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "aws_filter" {
  description = "Name filter and owner for AMI"

  type = object({
    name = string
    owner = string
  })

  default = {
    name   = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
    owners = "979382823631" # Bitnami
  }
}

variable "environment" {
  description = "Developement Environment"

  type = object({
    name = string
    network_prefix = string
  })

  default = {
    name = "dev"
    network_prefix = "10.0"
  }
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  default = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  default = 2
}
