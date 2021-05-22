module "ssh_key_pair_admin" {
  source = "cloudposse/key-pair/aws"
  version     = ">=0.18.0"
  namespace             = "netflix"
  stage                 = "prod"
  name                  = "admin"
  ssh_public_key_path   = ".secrets"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

resource "null_resource" "remove_ssh_key" {
  triggers = {
    "always_run" = timestamp()
  }
  provisioner "local-exec" {
    command = "rm -rf ${module.ssh_key_pair_admin.private_key_filename}"
  }
}

resource "local_file" "private_key_admin" {
    sensitive_content = module.ssh_key_pair_admin.private_key
    filename = module.ssh_key_pair_admin.private_key_filename
    file_permission = "0400"
    depends_on = [null_resource.remove_ssh_key]
}

module "ssh_key_pair_bastion" {
  source = "cloudposse/key-pair/aws"
  version     = ">=0.18.0"
  namespace             = "netflix"
  stage                 = "prod"
  name                  = "bastion"
  ssh_public_key_path   = ".secrets"
  generate_ssh_key      = true#!fileexists(".secrets/netflix-prod-bastion.pem")
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

resource "aws_instance" "bastion-host" {
  ami = data.aws_ami.ubuntu-server.id
  instance_type = var.instance_type
  subnet_id = lookup(aws_subnet.netflix-public, data.aws_availability_zones.all.names[0]).id
  security_groups = [ aws_security_group.allow_global_ssh.id ]
  # key_name = "awsec2"
  key_name = module.ssh_key_pair_admin.key_name
  tags = {
    "Name" = "Bastion host"
  }
  provisioner "file" {
    #FIXME sensitive information here
    content = module.ssh_key_pair_bastion.private_key
    destination = "~/.ssh/id_rsa"
    connection {
      host = self.public_ip
      user = "ubuntu"
      type = "ssh"
      private_key = module.ssh_key_pair_admin.private_key
    }
  }
  provisioner "remote-exec" {
    inline = ["chmod 400 ~/.ssh/id_rsa"]
    connection {
      host = self.public_ip
      user = "ubuntu"
      type = "ssh"
      private_key = module.ssh_key_pair_admin.private_key
    }
  }
  provisioner "file" {
    #FIXME sensitive information
    content = templatefile("${path.module}/host_aliases.tpl", {nodes = {for alias, node in aws_instance.worker-node : alias => node.private_ip}})
    destination = "~/.host_aliases"
    connection {
      host = self.public_ip
      user = "ubuntu"
      type = "ssh"
      private_key = module.ssh_key_pair_admin.private_key
    }
  }
  provisioner "remote-exec" {
    inline = ["echo \"if [ -f ~/.host_aliases ]; then . ~/.host_aliases; fi\" >> ~/.bashrc"]
    connection {
      host = self.public_ip
      user = "ubuntu"
      type = "ssh"
      private_key = module.ssh_key_pair_admin.private_key
    }
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
  instances-spread = {
    for a in toset(local.instances-data) : format("%s_%s", a.service, a.az) => a
  }
}

resource "aws_instance" "worker-node" {
  ami = data.aws_ami.ubuntu-server.id
  instance_type = var.instance_type
  # key_name = "awsec2"
  key_name = module.ssh_key_pair_bastion.key_name
  for_each = local.instances-spread
  subnet_id = lookup(aws_subnet.netflix-private, each.value.az).id
  security_groups = [ aws_security_group.allow_public_ssh.id, aws_security_group.allow_public_http.id, aws_security_group.http_global_outgoing.id ]
  user_data = templatefile("${path.module}/setup_worker_node.tpl", {worker_name = each.value.service, az = each.value.az, services = var.services})
  tags = {
    "Name" = "Worker node ${each.value.service} in ${each.value.az}"
  }
}

