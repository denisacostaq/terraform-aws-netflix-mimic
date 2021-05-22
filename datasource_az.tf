#https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-availability-zones.html
data "aws_availability_zones" "all" {
  filter {
    name = "region-name"
    values = [var.aws_region]
  }
}