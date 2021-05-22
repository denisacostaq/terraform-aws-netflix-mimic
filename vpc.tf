resource "aws_vpc" "service" {
  cidr_block       = "10.1.0.0/16"
  tags = {
    "Name" = "service"
  }
}

resource "aws_subnet" "service-private" {
  vpc_id            = aws_vpc.service.id
  for_each = toset(data.aws_availability_zones.all.names)
  availability_zone = each.value
  cidr_block        = format("10.1.%d.0/24", index(data.aws_availability_zones.all.names, each.value) + 1)
  tags = {
    "Name" = "service-private-${each.value}"
  }
}

resource "aws_subnet" "service-public" {
  vpc_id            = aws_vpc.service.id
  for_each = toset(data.aws_availability_zones.all.names)
  availability_zone = each.value
  cidr_block        = format("10.1.%d.0/24", length(data.aws_availability_zones.all.names) + index(data.aws_availability_zones.all.names, each.value) + 1)
  map_public_ip_on_launch = true
  tags = {
    "Name" = "service-public-${each.value}"
  }
}

resource "aws_internet_gateway" "service-gw" {
  vpc_id = aws_vpc.service.id
  tags = {
    "Name" = "service"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "allow_egress" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = lookup(aws_subnet.service-public, data.aws_availability_zones.all.names[0]).id
  tags = {
    "Name" = "service-public"
  }
  depends_on = [aws_internet_gateway.service-gw]
}

resource "aws_route_table" "noninternet-route-table" {
  vpc_id = aws_vpc.service.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.allow_egress.id
  }
}

resource "aws_route_table" "internet-route-table" {
  vpc_id = aws_vpc.service.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.service-gw.id
  }
}

resource "aws_route_table_association" "internet" {
  for_each = aws_subnet.service-public
  route_table_id = aws_route_table.internet-route-table.id
  subnet_id = each.value.id
}

resource "aws_route_table_association" "noninternet" {
  for_each = aws_subnet.service-private
  route_table_id = aws_route_table.noninternet-route-table.id
  subnet_id = each.value.id
}

resource "aws_security_group" "allow_global_ssh" {
  name = "SSH global"
  description = "Allow ssh global incoming ssh trafic, and private outgoin"
  vpc_id = aws_vpc.service.id
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow global incoming ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  egress {
    cidr_blocks = [for np in aws_subnet.service-private: np.cidr_block]
    description = "Allow outgoing ssh to private subnets"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  tags = {
    "Name" = "allow_global_ssh"
  }
}

resource "aws_security_group" "allow_public_ssh" {
  name = "SSH public"
  description = "Allow ssh public incoming trafic"
  vpc_id = aws_vpc.service.id
  ingress {
    cidr_blocks = [for np in aws_subnet.service-public: np.cidr_block]
    description = "Allow public incoming ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  tags = {
    "Name" = "allow_public_ssh"
  }
}

resource "aws_security_group" "allow_public_http" {
  name = "HTTP public"
  description = "Allow http public outgoin trafic"
  vpc_id = aws_vpc.service.id
  ingress {
    cidr_blocks = [for np in aws_subnet.service-public: np.cidr_block]
    description = "Allow public incoming http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  tags = {
    "Name" = "allow_public_http"
  }
}

resource "aws_security_group" "allow_global_http" {
  name = "HTTP global"
  description = "Allow http global outgoin trafic"
  vpc_id = aws_vpc.service.id
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow global incoming http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  egress {
    cidr_blocks = [for np in aws_subnet.service-private: np.cidr_block]
    description = "Allow outgoing http to private subnets"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  tags = {
    "Name" = "allow_global_http"
  }
}

resource "aws_security_group" "http_global_outgoing" {
  name = "http_global_outgoing"
  description = "Allow global http outgoin trafic (APT)"
  vpc_id = aws_vpc.service.id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow global outgoing http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  tags = {
    "Name" = "http_global_outgoing"
  }
}
