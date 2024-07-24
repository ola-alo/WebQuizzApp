# Create vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  # enable_dns_hostnames = true

  tags = {
    Name = "prod-vpc"
  }  
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create private subnet on az1
resource "aws_subnet" "subnet_a" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  # map_public_ip_on_launch = true
  
  tags = {
    name = "prod_subnet_a"
  }
}

# create private subnet on az1
resource "aws_subnet" "subnet_b" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[1]
  # map_public_ip_on_launch = true
  
  tags = {
    name = "prod_subnet_b"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    name = "my_IGW"
  }
}

# Create a custom route table
resource "aws_route_table" "route_tablee" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    name = "my_route_table"
  }
}

# create route
resource "aws_route" "routee" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id  = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.route_tablee.id
}

resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_tablee.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_tablee.id
}

# Create a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  name        = "lb_sg"
  description = "security group for the load_balancer"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Permit incoming HTTP requests from the internet"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Permit all outgoing requests to the internet"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# To ensure access for ecs service with more secure vpc create a aws security group service.
resource "aws_security_group" "service_security_group" {
  name        = "service_sg"
  description = "security group for the ecs service"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #allowing the traffic from load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create a load balancer:
resource "aws_lb" "application_load_balancer" {
  name               = "load-balancer-dev" #load balancer name
  load_balancer_type = "application"
  subnets = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  internal           = false
  # security group
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

# Configure the load balancer with the VPC network
resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.application_load_balancer.arn}" #  load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # target group
  }
}


# Create repository for image
resource "aws_ecr_repository" "app_ecr_repo" {
  name = "app-repo"
}

# create esc cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "app-cluster" 
}
