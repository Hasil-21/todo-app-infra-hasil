resource "aws_vpc" "this" {
    cidr_block = var.cidr_block
    
    tags = {
      Name = "${var.name}-vpc"
    }
}

resource "aws_subnet" "private" {
    count = length(var.private_subnet_ids)
    vpc_id = aws_vpc.this.id
    cidr_block = var.private_subnet_ids[count.index]
    availability_zone = var.availability_zone[count.index]

    tags = {
      Name = "${var.name}-private-subnet-${var.private_subnet_ids[count.index]}"
      "kubernetes.io/role/internal-elb" = 1
      "kubernetes.io/cluster/todo-app-cluster" = "shared"
    }
}

resource "aws_subnet" "public" {
    count = length(var.public_subnet_ids)
    vpc_id = aws_vpc.this.id
    cidr_block = var.public_subnet_ids[count.index]
    availability_zone = var.availability_zone[count.index]
    map_public_ip_on_launch = true

    tags = {
      Name = "${var.name}-public-subnet-${var.public_subnet_ids[count.index]}"
      "kubernetes.io/role/elb" = 1
      "kubernetes.io/cluster/todo-app-cluster" = "shared"
    }
}

resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id
    
    tags = {
      Name = "${var.name}-igw"
    }
}

resource "aws_eip" "this" {
    domain = "vpc"

    tags = {
      Name = "${var.name}-eip"
    }
}

resource "aws_nat_gateway" "this" {
    subnet_id = aws_subnet.public[1].id
    allocation_id = aws_eip.this.allocation_id

    tags = {
      Name = "${var.name}-nat"
    }

    depends_on = [ aws_internet_gateway.this ]
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.this.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.this.id
    }

    tags = {
        Name = "${var.name}-private-rt"
    }
}

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_ids)
    route_table_id = aws_route_table.private.id
    subnet_id = aws_subnet.private[count.index].id
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this.id
    }

    tags = {
        Name = "${var.name}-public-rt"
    }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_ids)
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public[count.index].id
}