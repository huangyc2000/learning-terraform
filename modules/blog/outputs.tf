/* comment out for autoscaling
#output "instance_ami" {
#  value = aws_instance.web.ami
#}

#output "instance_arn" {
#  value = aws_instance.web.arn
#} */

output "environment_url" {
    value = module.blog_alb.dns_name
}