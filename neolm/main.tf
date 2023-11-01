# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change this to your desired AWS region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet within the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24" # Adjust the CIDR block as needed
  availability_zone = "us-east-1a" # Change this to your desired availability zone
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a security group
resource "aws_security_group" "my_sg" {
  name        = "my-instance-sg"
  description = "Security group for my instance"
  vpc_id      = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Define inbound rules (SSH and HTTP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a routing table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.my_igw.id
    }
  tags = {
      Name = "labRT"
    }
}

# Associate the routing table with our subnet
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.rt.id
}
# Create an EC2 instance
resource "aws_instance" "my_instance" {
  ami           = "ami-0dbc3d7bc646e8516" # Specify your desired AMI ID
  instance_type = "t2.micro" # Adjust the instance type as needed
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name      = "terraform-key" # Change this to your SSH key pair
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd.service
              sudo systemctl enable httpd.service
              sudo echo "<h1> At $(hostname -f) done by <b> Shukhrat Ismailov</b> </h1>" > /var/www/html/index.html                   
              EOF
  tags = {
    Name = "MyInstance"
  }
}