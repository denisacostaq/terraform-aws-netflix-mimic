resource "aws_instance" "bastion-host" {
  ami = data.aws_ami.ubuntu-server.id
  instance_type = var.instance_type
  subnet_id = lookup(aws_subnet.netflix-public, data.aws_availability_zones.all.names[0]).id
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
    #make in a single place
    for a in toset(local.instances-data): format("%s_%s", a.az, a.service) => a
  }
  subnet_id = lookup(aws_subnet.netflix-private, each.value.az).id
  security_groups = [ aws_security_group.allow_public_ssh.id, aws_security_group.allow_public_http.id, aws_security_group.http_global_outgoing.id ]
  user_data = templatefile("${path.module}/setup_worker_node.tpl", {worker_name = each.value.service, az = each.value.az})
  tags = {
    "Name" = "Worker node ${each.value.service} in ${each.value.az}"
  }
}

