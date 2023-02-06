provider "aws" {
  region  = "us-east-1a"
  profile = "default"
  #  access_key = var.access_key
  #  secret_key = var.secret_key
}


# Creating My VPC

resource "aws_vpc" "Altschool_project_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Altschool_project_vpc"
  }
}


# Creating my Internet Gateway

resource "aws_internet_gateway" "Altschool_project_internet_gateway" {
  vpc_id = aws_vpc.Altschool_project_vpc.id
  tags = {
    Name = "Altschool_internet_gateway"
  }
}

# Creating my Public Route Table

resource "aws_route_table" "Altschool-project-route-table-public" {
  vpc_id = aws_vpc.Altschool_project_vpc.id



  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Altschool_project_internet_gateway.id
  }

  tags = {
    Name = "Altschool-project-route-table-public"
  }
}


# Associating my public subnet 1 with my public route table

resource "aws_route_table_association" "Altschool-project-public-subnet1-association" {
  subnet_id      = aws_subnet.Altschool-project-public-subnet1.id
  route_table_id = aws_route_table.Altschool-project-route-table-public.id
}

# Associating my public subnet 2 with my public route table

resource "aws_route_table_association" "Altschool-project-public-subnet2-association" {
  subnet_id      = aws_subnet.Altschool-project-public-subnet2.id
  route_table_id = aws_route_table.Altschool-project-route-table-public.id
}


# Creating my Public Subnet-1

resource "aws_subnet" "Altschool-project-public-subnet1" {
  vpc_id                  = aws_vpc.Altschool_project_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"
  tags = {
    Name = "Altschool-project-public-subnet1"
  }
}

# Creating my Public Subnet-2

resource "aws_subnet" "Altschool-project-public-subnet2" {
  vpc_id                  = aws_vpc.Altschool_project_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2b"
  tags = {
    Name = "Altschool-project-public-subnet2"
  }
}




resource "aws_network_acl" "Altschool-project-network_acl" {
  vpc_id     = aws_vpc.Altschool_project_vpc.id
  subnet_ids = [aws_subnet.Altschool-project-public-subnet1.id, aws_subnet.Altschool-project-public-subnet2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# Creating a security group for the load balancer

resource "aws_security_group" "Altschool-project-load_balancer_sg" {
  name        = "Altschool-project-load-balancer-sg"
  description = "This is the security group for my load balancer"
  vpc_id      = aws_vpc.Altschool_project_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating Security Group to allow port 22, 80 and 443

resource "aws_security_group" "Altschool-project-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.Altschool_project_vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Altschool-project-load_balancer_sg.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Altschool-project-load_balancer_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "Altschool-project-security-grp-rule"
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# resource "aws_key_pair" "kp" {
#  key_name   = "joshmawKey"       # Create a "joshmawKey" to AWS!!
#  public_key = tls_private_key.pk.public_key_openssh

#  provisioner "local-exec" { # Create a "joshmawKey.pem" to your computer!!
#    command = "echo '${tls_private_key.pk.private_key_pem}' > ./joshmawKey.pem"
#  }
# }

# resource "aws_key_pair" "deploy" {
#  key_name   = "joshmaw-key"
#  public_key = "ssh-rsa "
# }

# creating instance 1

resource "aws_instance" "Altschool-project1" {
  ami           = "ami-01b8d743224353ffe"
  instance_type = "t2.micro"
  #  key_name        = "default"
  security_groups   = [aws_security_group.Altschool-project-security-grp-rule.id]
  subnet_id         = aws_subnet.Altschool-project-public-subnet1.id
  availability_zone = "eu-west-2a"
  tags = {
    Name   = "Altschool-project-1"
    source = "terraform"
  }
}

# creating instance 2

resource "aws_instance" "Altschool-project2" {
  ami           = "ami-01b8d743224353ffe"
  instance_type = "t2.micro"
  #  key_name        = "joshmaw-key"
  security_groups   = [aws_security_group.Altschool-project-security-grp-rule.id]
  subnet_id         = aws_subnet.Altschool-project-public-subnet2.id
  availability_zone = "eu-west-2b"
  tags = {
    Name   = "Altschool-project-2"
    source = "terraform"
  }
}


# creating instance 3

resource "aws_instance" "Altschool-project3" {
  ami           = "ami-01b8d743224353ffe"
  instance_type = "t2.micro"
  #  key_name        = "joshmaw-key"
  security_groups   = [aws_security_group.Altschool-project-security-grp-rule.id]
  subnet_id         = aws_subnet.Altschool-project-public-subnet1.id
  availability_zone = "us-east-1"
  tags = {
    Name   = "Altschool-project-3"
    source = "terraform"
  }
}


# Creating a file to store the IP addresses of my 3 instances

resource "local_file" "Ip_address" {
  filename = "/root/terraform_assignment/host-inventory"
  content  = <<EOT
${aws_instance.Altschool-project1.public_ip}
${aws_instance.Altschool-project2.public_ip}
${aws_instance.Altschool-project3.public_ip}
  EOT
}


# Create an Application Load Balancer

resource "aws_lb" "Altschool-project-load-balancer" {
  name               = "Altschool-project-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Altschool-project-load_balancer_sg.id]
  subnets            = [aws_subnet.Altschool-project-public-subnet1.id, aws_subnet.Altschool-project-public-subnet2.id]
  #enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.Altschool-project1, aws_instance.Altschool-project2, aws_instance.Altschool-project3]
}


# Create the target group

resource "aws_lb_target_group" "Altschool-target-group" {
  name        = "Altschool-target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.Altschool_project_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


# Create the listener

resource "aws_lb_listener" "Altschool-listener" {
  load_balancer_arn = aws_lb.Altschool-project-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
}

# Create the listener rule

resource "aws_lb_listener_rule" "Altschool-listener-rule" {
  listener_arn = aws_lb_listener.Altschool-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}


# Attach the target group to the load balancer

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool-project1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool-project2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool-project3.id
  port             = 80

}


