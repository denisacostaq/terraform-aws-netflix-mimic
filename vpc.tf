resource "aws_vpc" "netflix" {
  cidr_block       = "10.1.0.0/16"
  tags = {
    "Name" = "netflix"
  }
}

resource "aws_subnet" "public-1a" {
  vpc_id            = aws_vpc.netflix.id
  availability_zone = "eu-central-1a"
  cidr_block        = "10.1.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "netflix-public-1a"
  }
}

resource "aws_subnet" "private-1a" {
  vpc_id            = aws_vpc.netflix.id
  availability_zone = "eu-central-1a"
  cidr_block        = "10.1.2.0/24"
  tags = {
    "Name" = "netflix-private-1a"
  }
}

resource "aws_subnet" "public-1b" {
  vpc_id            = aws_vpc.netflix.id
  availability_zone = "eu-central-1b"
  cidr_block        = "10.1.3.0/24"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "netflix-public-1b"
  }
}

resource "aws_subnet" "private-1b" {
  vpc_id            = aws_vpc.netflix.id
  availability_zone = "eu-central-1b"
  cidr_block        = "10.1.4.0/24"
  tags = {
    "Name" = "netflix-private-1b"
  }
}

resource "aws_internet_gateway" "netflix-gw" {
  vpc_id = aws_vpc.netflix.id
  tags = {
    "Name" = "netflix"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "allow_egress" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.public-1a.id
  tags = {
    "Name" = "netflix"
  }
  depends_on = [aws_internet_gateway.netflix-gw]
}

resource "aws_route_table" "noninternet-route-table" {
  vpc_id = aws_vpc.netflix.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.allow_egress.id
  }
}

resource "aws_route_table" "internet-route-table" {
  vpc_id = aws_vpc.netflix.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.netflix-gw.id
  }
}

resource "aws_route_table_association" "internet-1a" {
  route_table_id = aws_route_table.internet-route-table.id
  subnet_id = aws_subnet.public-1a.id
}

resource "aws_route_table_association" "internet-1b" {
  route_table_id = aws_route_table.internet-route-table.id
  subnet_id = aws_subnet.public-1b.id
}

resource "aws_route_table_association" "noninternet-1a" {
  route_table_id = aws_route_table.noninternet-route-table.id
  subnet_id = aws_subnet.private-1a.id
}

resource "aws_route_table_association" "noninternet-1b" {
  route_table_id = aws_route_table.noninternet-route-table.id
  subnet_id = aws_subnet.private-1b.id
}

resource "aws_security_group" "allow_global_ssh" {
  name = "SSH global"
  description = "Allow ssh global incoming ssh trafic, and private outgoin"
  vpc_id = aws_vpc.netflix.id
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow global incoming ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  egress {
    cidr_blocks = [aws_subnet.private-1a.cidr_block, aws_subnet.private-1b.cidr_block]
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
  vpc_id = aws_vpc.netflix.id
  ingress {
    cidr_blocks = [ aws_subnet.public-1a.cidr_block, aws_subnet.public-1b.cidr_block ]
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
  vpc_id = aws_vpc.netflix.id
  ingress {
    cidr_blocks = [aws_subnet.public-1a.cidr_block, aws_subnet.public-1b.cidr_block ]
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
  vpc_id = aws_vpc.netflix.id
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow global incoming http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  egress {
    cidr_blocks = [aws_subnet.private-1a.cidr_block, aws_subnet.private-1b.cidr_block]
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
  vpc_id = aws_vpc.netflix.id
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
