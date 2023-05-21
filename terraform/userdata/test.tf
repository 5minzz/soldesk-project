provider "aws" {
  region = "ap-northeast-2"
}


#################### Public Key 업로드 ####################
resource "aws_key_pair" "Project-Key" {
  key_name   = "Project-Key"
  public_key = file("C:\\Users\\Yang\\terraform\\project\\projectPUB.pub")
}


#################### VPC 생성 ####################
resource "aws_vpc" "Project-VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project-VPC"
  }
}


#################### Internet Gateway 생성 ####################
resource "aws_internet_gateway" "Project-IGW" {
  vpc_id = aws_vpc.Project-VPC.id
  tags = {
    Name = "Project-IGW"
  }
}


#################### Public Subnet 1, 2 생성 ####################
resource "aws_subnet" "Public-Subnet1" {
  vpc_id     = aws_vpc.Project-VPC.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "Public-Subnet1"
  }
}

resource "aws_subnet" "Public-Subnet2" {
  vpc_id     = aws_vpc.Project-VPC.id
  cidr_block = "10.0.3.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "Public-Subnet2"
  }
}

#################### Public Routing Table 생성 ####################
resource "aws_route_table" "Public-RT" {
  vpc_id = aws_vpc.Project-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Project-IGW.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table_association" "Public-RT-Association1" {
  subnet_id      = aws_subnet.Public-Subnet1.id
  route_table_id = aws_route_table.Public-RT.id
}

resource "aws_route_table_association" "Public-RT-Association2" {
  subnet_id      = aws_subnet.Public-Subnet2.id
  route_table_id = aws_route_table.Public-RT.id
}

#################### Bastion Host SG 생성 ####################
resource "aws_security_group" "Bastion-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "Bastion-SG"

  tags = {
    name = "Bastion-SG"
  }
}


#################### Bastion Host SG 인바운드 규칙 ####################	
resource "aws_security_group_rule" "ELB-SG-In" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Bastion-SG.id
}

resource "aws_security_group_rule" "ELB-SG-ping" { 
  type        = "ingress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Bastion-SG.id
}


#################### Bastion Host SG 아웃바운드 규칙 ####################
resource "aws_security_group_rule" "ELB-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Bastion-SG.id
}


#################### Web Server1 SG 생성 ####################
resource "aws_security_group" "Web-Server1-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "Web-Server1-SG"

  tags = {
    name = "Web-Server1-SG"
  }
}


#################### Web Server1 SG 인바운드 규칙 ####################	
resource "aws_security_group_rule" "Bastion-Web-Server1-HTTP-SG-IN" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.1.0/24"]

  security_group_id = aws_security_group.Web-Server1-SG.id
  #source_security_group_id = "${aws_security_group.Web-Server-SG.id}"

}

resource "aws_security_group_rule" "Bastion-Web-Server1-SSH-SG-IN" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.1.0/24"]

  security_group_id = aws_security_group.Web-Server1-SG.id
}

resource "aws_security_group_rule" "Bastion-Web-Server1-PING-SG" {
  type        = "ingress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  cidr_blocks = ["10.0.1.0/24"]

  security_group_id = aws_security_group.Web-Server1-SG.id
}


#################### Web Server1 SG 아웃바운드 규칙 ####################
resource "aws_security_group_rule" "Bastion-Web-Server1-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Web-Server1-SG.id
}

#################### Bastion Host EC2 2대 생성 ####################
resource "aws_instance" "Project-EC2-1" {
  ami                    = "ami-0fd0765afb77bcca7"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.Public-Subnet1.id
  vpc_security_group_ids = [aws_security_group.Bastion-SG.id]
  key_name               = aws_key_pair.Project-Key.key_name

  availability_zone           = "ap-northeast-2a"
  associate_public_ip_address = true

  #Bastion Host1 PEM키 넣어주기
  user_data = <<-EOF
        #!/bin/bash
        sudo amazon-linux-extras install epel -y
        sudo yum install stress -y 
    EOF

  tags = {
    Name = "Bastion-Server1"
  }
}