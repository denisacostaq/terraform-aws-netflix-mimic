#https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-availability-zones.html
data "aws_availability_zones" "all" {
  filter {
    name = "region-name"
    values = ["eu-central-1"] # TODO make it a variable
  }
}