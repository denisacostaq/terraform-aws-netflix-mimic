#https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

data "aws_ami" "ubuntu-server" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd/ubuntu-focal-*-amd64-server-*" ]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
  filter {
    name = "image-type"
    values = [ "machine" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
}
