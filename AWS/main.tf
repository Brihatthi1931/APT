# provider "aws" {
#   region = "us-east-1"
# }

# # --- 1. Networking (VPC, Subnets, Gateways) ---
# resource "aws_vpc" "main" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   tags = { Name = "devops-assignment-vpc" }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id
# }

# # Public Subnets (For ALB and NAT Gateway)
# resource "aws_subnet" "public_1" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "us-east-1a"
#   map_public_ip_on_launch = true
# }

# resource "aws_subnet" "public_2" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true
# }

# # Private Subnets (For EC2 Instances - Source 94)
# resource "aws_subnet" "private_1" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.3.0/24"
#   availability_zone = "us-east-1a"
# }

# resource "aws_subnet" "private_2" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.4.0/24"
#   availability_zone = "us-east-1b"
# }

# # NAT Gateway (Required by Source 75, 96) - COST WARNING: Not Free Tier!
# resource "aws_eip" "nat" {
#   domain = "vpc"
# }

# resource "aws_nat_gateway" "main" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public_1.id
#   depends_on    = [aws_internet_gateway.igw]
# }

# # Route Tables
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.main.id
#   }
# }

# resource "aws_route_table_association" "pub_1" { subnet_id = aws_subnet.public_1.id; route_table_id = aws_route_table.public.id }
# resource "aws_route_table_association" "pub_2" { subnet_id = aws_subnet.public_2.id; route_table_id = aws_route_table.public.id }
# resource "aws_route_table_association" "priv_1" { subnet_id = aws_subnet.private_1.id; route_table_id = aws_route_table.private.id }
# resource "aws_route_table_association" "priv_2" { subnet_id = aws_subnet.private_2.id; route_table_id = aws_route_table.private.id }

# # --- 2. Security Groups (Source 80-82) ---
# resource "aws_security_group" "alb_sg" {
#   vpc_id = aws_vpc.main.id
#   name   = "alb-sg"

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from internet
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "ec2_sg" {
#   vpc_id = aws_vpc.main.id
#   name   = "ec2-sg"

#   ingress {
#     from_port       = 8080
#     to_port         = 8080
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id] # Allow only from ALB (Source 82)
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"] # Needed for NAT GW access
#   }
# }

# # --- 3. Load Balancer (Source 76-77, 98-101) ---
# resource "aws_lb" "main" {
#   name               = "app-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
# }

# resource "aws_lb_target_group" "app" {
#   name     = "app-tg"
#   port     = 8080
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id

#   health_check {
#     path                = "/health"
#     matcher             = "200"
#     interval            = 10
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }

# # --- 4. Auto Scaling & Compute (Source 78-79) ---
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# resource "aws_launch_template" "app" {
#   name_prefix   = "app-launch-template"
#   image_id      = data.aws_ami.amazon_linux.id
#   instance_type = "t2.micro" # Free Tier Eligible

#   network_interfaces {
#     associate_public_ip_address = false # Private instances (Source 95)
#     security_groups             = [aws_security_group.ec2_sg.id]
#   }

#   # User Data: Install python, create app file, run app (Source 97)
#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               yum update -y
#               yum install -y python3
#               pip3 install flask
              
#               mkdir /app
#               cat <<EOT > /app/app.py
#               from flask import Flask, jsonify
#               import logging
#               import sys
#               app = Flask(__name__)
#               logging.basicConfig(stream=sys.stdout, level=logging.INFO)
#               @app.route('/')
#               def home():
#                   return "Hello from Private EC2!"
#               @app.route('/health')
#               def health():
#                   return jsonify(status="ok")
#               if __name__ == '__main__':
#                   app.run(host='0.0.0.0', port=8080)
#               EOT

#               # Run app in background
#               nohup python3 /app/app.py > /var/log/app.log 2>&1 &
#               EOF
#   )
# }

# resource "aws_autoscaling_group" "asg" {
#   vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id] # Private subnets (Source 79)
#   desired_capacity    = 1
#   max_size            = 2
#   min_size            = 1
#   target_group_arns   = [aws_lb_target_group.app.arn] # Connect to ALB (Source 100)

#   launch_template {
#     id      = aws_launch_template.app.id
#     version = "$Latest"
#   }
# }

# # --- Outputs ---
# output "alb_dns_name" {
#   value       = aws_lb.main.dns_name
#   description = "The URL to access the API"
# }









provider "aws" {
  region = "ap-south-1"
}

# -----------------------
# VPC
# -----------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnets
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
}

# Private Subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# NAT Gateway (costly!)
resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------------
# Security Groups
# -----------------------

# ALB SG
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 SG
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------
# ALB + Target Group
# -----------------------
resource "aws_lb" "alb" {
  name               = "apt-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "apt-tg"
  port     = 8080
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# -----------------------
# Launch Template
# -----------------------
resource "aws_launch_template" "lt" {
  name_prefix   = "apt-lt"
  image_id      = "ami-0cda377a1b884a1bc"   # Amazon Linux 2
  instance_type = "t2.micro"

  user_data = filebase64("${path.module}/userdata.sh")

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
  }

}

# -----------------------
# ASG
# -----------------------
resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1

  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
}
