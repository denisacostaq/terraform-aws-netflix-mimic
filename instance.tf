resource "aws_instance" "bastion-host" {
  ami = data.aws_ami.ubuntu-server.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public-1a.id
  security_groups = [ aws_security_group.allow_global_ssh.id ]
  key_name = "awsec2"
  tags = {
    "Name" = "Bastion host"
  }
}

locals {
  instances-data = flatten([
    for az in data.aws_availability_zones.all.names : [
      for service in var.services : {
        service = service
        az = az
      }
    ]
  ])
}

resource "aws_instance" "worker-node" {
  ami = data.aws_ami.ubuntu-server.id
  instance_type = var.instance_type
  key_name = "awsec2"
  for_each = {
    for a in toset(local.instances-data): format("%s_%s", a.az, a.service) => a
  }
  subnet_id = aws_subnet.private-1a.id
  security_groups = [ aws_security_group.allow_public_ssh.id, aws_security_group.allow_public_http.id, aws_security_group.http_global_outgoing.id ]
  user_data = templatefile("${path.module}/setup_apache.tpl", {worker_name = each.value.service, az = each.value.az})
  tags = {
    "Name" = "Stream node"
  }
}

resource "aws_instance" "home-node" {
  ami = data.aws_ami.ubuntu-server.id
  instance_type = var.instance_type
  key_name = "awsec2"
  count = 1
  user_data = file("worker_node.sh")
  subnet_id = aws_subnet.private-1b.id
  security_groups = [ aws_security_group.allow_public_ssh.id, aws_security_group.allow_public_http.id, aws_security_group.http_global_outgoing.id ]
  tags = {
    "Name" = "Home node"
  }
}