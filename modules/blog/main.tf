data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

module "blog_sg" {
  source = "terraform-aws-module/security-group/aws"
  version = "4.13.0"

  name = "${var.environment.name}-blog"
  vpc_id = module.blog_vpc.vpc_id

  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.2.0"
  # insert the 1 required variable here

  name = "${var.environment.name}-blog"
  min_size = var.asg_min_size
  max_size = var.asg_max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets
  target_group_arns = module.blog_alb.target_group_arns
  security_groups = [module.blog_sg.security_group_id]

  image_id = data.aws_ami.ami_app_ami.id
  instance_type = var.instance_type
}


module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  load_balancer_type = "application"

  name    = "${var.environment.name}-blog-alb"
  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets

  # Security Group
  security_groups = [module.blog_sg.security_group_id]

  access_logs = {
    bucket = "blog-alb-logs"
  }

  http_tcp_listners = {
    {
      port     = 80
      protocol = "HTTP"
      target_group_index = 0      
    }
  }

  /*
  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  } */

  target_groups = {
    ex-instance = {
      name_prefix      = "${var.environment.name}-"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      /* comment out for autoscaling
      target_id        = aws_instance.blog.id
      */
    }
  }

  tags = {
    Environment = var.environment.name
    Project     = "Example"
  }
}