resource "aws_vpc" "netflix" {
  cidr_block       = "10.1.0.0/16"
  tags = {
    "Name" = "netflix"
  }
}

resource "aws_internet_gateway" "netflix-gw" {
  vpc_id = aws_vpc.netflix.id
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

resource "aws_route_table" "noninternet-route-table" {
  vpc_id = aws_vpc.netflix.id
}

resource "aws_route_table" "internet-route-table" {
  vpc_id = aws_vpc.netflix.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.netflix-gw.id
  }
  # FIXME local network
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