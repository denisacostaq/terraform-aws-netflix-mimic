variable "instance_type" {
  description = "AWS instance type"
  type = string
  default = "t2.micro"
}

variable "services" {
  description = "Desired services to deploy"
  type = list
  default = ["home", "watch"]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
