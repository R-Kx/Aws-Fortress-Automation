data "aws_availability_zones" "available_zones" {
    state = "available"
}

resource "aws_vpc" "flask_vpc" {
    cidr_block           = var.vpc_cidr
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true 
}

resource "aws_subnet" "public" {
    count                   = var.azs
    vpc_id                  = aws_vpc.flask_vpc.id
    cidr_block              = cidrsubnet(aws_vpc.flask_vpc.cidr_block, 8, count.index + 1)
    availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
    map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
    count             = var.azs
    vpc_id            = aws_vpc.flask_vpc.id
    cidr_block        = cidrsubnet(aws_vpc.flask_vpc.cidr_block, 8, count.index + 11)
    availability_zone = data.aws_availability_zones.available_zones.names[count.index]
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.flask_vpc.id
}

resource "aws_eip" "nat_eip" {
    domain     = "vpc"
    depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
    connectivity_type = "public"
    allocation_id     = aws_eip.nat_eip.id
    subnet_id         = aws_subnet.public[0].id
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.flask_vpc.id
}

resource "aws_route" "public_r" {
    route_table_id         = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_asso" {
    count          = var.azs
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.flask_vpc.id
}

resource "aws_route" "private_r" {
    route_table_id         = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_rt_asso" {
    count          = var.azs
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id            = aws_vpc.flask_vpc.id
    service_name      = "com.amazonaws.${var.default_region}.s3"
    vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
    route_table_id  = aws_route_table.public_rt.id
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
    route_table_id  = aws_route_table.private_rt.id
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint" "secrets_manager" {
    vpc_id              = aws_vpc.flask_vpc.id
    service_name        = "com.amazonaws.${var.default_region}.secretsmanager"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    private_dns_enabled = true
    security_group_ids  = [aws_security_group.secrets_sg.id]
}