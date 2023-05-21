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


#################### Private Subnet 1, 2 생성 ####################
resource "aws_subnet" "Private-Subnet1" {
  vpc_id     = aws_vpc.Project-VPC.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "Private-Subnet1"
  }
}

resource "aws_subnet" "Private-Subnet2" {
  vpc_id     = aws_vpc.Project-VPC.id
  cidr_block = "10.0.4.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "Private-Subnet2"
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


#################### Private Routing Table 생성 ####################
resource "aws_route_table" "Private-RT-1" {
  vpc_id = aws_vpc.Project-VPC.id

  tags = {
    Name = "Private-RT-1"
  }
}

resource "aws_route_table" "Private-RT-2" {
  vpc_id = aws_vpc.Project-VPC.id

  tags = {
    Name = "Private-RT-2"
  }
}

resource "aws_route_table_association" "Private-RT-Association1" {
  subnet_id      = aws_subnet.Private-Subnet1.id
  route_table_id = aws_route_table.Private-RT-1.id
}

resource "aws_route_table_association" "Private-RT-Association2" {
  subnet_id      = aws_subnet.Private-Subnet2.id
  route_table_id = aws_route_table.Private-RT-2.id
}


#################### EIP 생성 ####################
resource "aws_eip" "NAT-EIP-1" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "NAT-EIP-1"
  }
}

resource "aws_eip" "NAT-EIP-2" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "NAT-EIP-2"
  }
}


#################### NAT Gateway 1, 2 생성 ####################
resource "aws_nat_gateway" "NAT-GW-1" {
  allocation_id = aws_eip.NAT-EIP-1.id

  subnet_id = aws_subnet.Public-Subnet1.id

  tags = {
    Name = "NAT-GW-1"
  }
}

resource "aws_nat_gateway" "NAT-GW-2" {
  allocation_id = aws_eip.NAT-EIP-2.id

  subnet_id = aws_subnet.Public-Subnet2.id

  tags = {
    Name = "NAT-GW-2"
  }
}


#################### NAT - PRIV 연결 ####################
resource "aws_route" "Private-RT-NAT-1" {
  route_table_id         = aws_route_table.Private-RT-1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NAT-GW-1.id
}
resource "aws_route" "Private-RT-NAT-2" {
  route_table_id         = aws_route_table.Private-RT-2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NAT-GW-2.id
}


#################### Bastion Host SG 생성 ####################
resource "aws_security_group" "Bastion-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "Bastion-SG"

  tags = {
    Name = "Bastion-SG"
  }
}


# Bastion Host SG 인바운드 규칙 #  
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


# Bastion Host SG 아웃바운드 규칙 #
resource "aws_security_group_rule" "ELB-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Bastion-SG.id
}


# Web Server1 SG 생성 #
resource "aws_security_group" "Web-Server1-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "Web-Server1-SG"

  tags = {
    Name = "Web-Server1-SG"
  }
}


# Web Server1 SG 인바운드 규칙 #
resource "aws_security_group_rule" "Bastion-Web-Server1-HTTP-SG-IN" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.1.0/24"]

  security_group_id = aws_security_group.Web-Server1-SG.id
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


# Web Server1 SG 아웃바운드 규칙 #
resource "aws_security_group_rule" "Bastion-Web-Server1-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Web-Server1-SG.id
}


#################### Web Server2 SG 생성 ####################
resource "aws_security_group" "Web-Server2-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "Web-Server2-SG"

  tags = {
    Name = "Web-Server2-SG"
  }
}


# Web Server2 SG 인바운드 규칙 # 
resource "aws_security_group_rule" "Bastion-Web-Server2-HTTP-SG-IN" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.3.0/24"]

  security_group_id = aws_security_group.Web-Server2-SG.id
}

resource "aws_security_group_rule" "Bastion-Web-Server2-SSH-SG-IN" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.3.0/24"]

  security_group_id = aws_security_group.Web-Server2-SG.id
}

resource "aws_security_group_rule" "Bastion-Web-Server2-PING-SG" {
  type        = "ingress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  cidr_blocks = ["10.0.3.0/24"]

  security_group_id = aws_security_group.Web-Server2-SG.id
}


# Web Server2 SG 아웃바운드 규칙 #
resource "aws_security_group_rule" "Bastion-Web-Server2-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.Web-Server2-SG.id
}

#################### User_data용 PEM키 파일 ####################
data "template_file" "user_data" {
  template = file("C:\\Users\\Yang\\terraform\\project\\install.sh")
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

  # Bastion Host1 PEM키 삽입 #
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "Bastion-Server1"
  }
}

resource "aws_instance" "Project-EC2-2" {
  ami                    = "ami-0fd0765afb77bcca7"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.Public-Subnet2.id
  vpc_security_group_ids = [aws_security_group.Bastion-SG.id]
  key_name               = aws_key_pair.Project-Key.key_name

  availability_zone           = "ap-northeast-2c"
  associate_public_ip_address = true

  # Bastion Host2 PEM키 삽입 #
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "Bastion-Server2"
  }
}

#################### ELB SG 생성 ####################
resource "aws_security_group" "ELB-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "ELB-SG"

  tags = {
    Name = "ELB-SG"
  }
}

# ELB SG 인바운드 #
resource "aws_security_group_rule" "ELB-SG-HTTP-In" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ELB-SG.id
}

# ELB SG 아웃바운드 규칙 #
resource "aws_security_group_rule" "ELB-SG-HTTP-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ELB-SG.id
}

#################### ELB 생성 ##############################
resource "aws_lb" "Project-ELB" {
  name               = "Project-ELB"
  subnets            = [aws_subnet.Public-Subnet1.id, aws_subnet.Public-Subnet2.id]
  security_groups    = [aws_security_group.ELB-SG.id]
  load_balancer_type = "application"

  tags = {
    Name = "Project-ELB"
  }
}

# ELB 타겟 그룹 생성 #
resource "aws_lb_target_group" "Project-ELB-TG" {
  name     = "Project-ELB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Project-VPC.id

  health_check {
    interval            = 10
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# ELB Listener 추가 #
resource "aws_lb_listener" "ALB-LISTENER-HTTP" {
  load_balancer_arn = aws_lb.Project-ELB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.Project-ELB-TG.arn
    type             = "forward"
  }
}


#################### User_data용 PEM키 파일 ####################
data "template_file" "setting" {
  template = file("C:\\Users\\Yang\\terraform\\project\\setting.sh")
}


#################### Auto Scaling 시작 구성 ####################
resource "aws_launch_configuration" "Project-LaunchConfig" {
  image_id      = "ami-0fd0765afb77bcca7"
  instance_type = "t2.micro"

  security_groups = [aws_security_group.Web-Server1-SG.id, aws_security_group.Web-Server2-SG.id]
  key_name        = aws_key_pair.Project-Key.key_name

  user_data = data.template_file.setting.rendered

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group 생성 #
resource "aws_autoscaling_group" "Web-Server-ASG" {
  launch_configuration = aws_launch_configuration.Project-LaunchConfig.id
  target_group_arns    = [aws_lb_target_group.Project-ELB-TG.arn]
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_subnet.Private-Subnet1.id, aws_subnet.Private-Subnet2.id]

  min_size = 2
  max_size = 4

  tag {
    key                 = "Name"
    value               = "Web-Server-ASG"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "Project-ASG-Policy" {
  name                   = "Project-ASG-Policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.Web-Server-ASG.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}


#################### DB 보안그룹 생성 ####################
resource "aws_security_group" "DB-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "DB-SG"

  tags = {
    Name = "DB-SG"
  }
}

# DB-SG 인바운드 규칙 추가 #
resource "aws_security_group_rule" "DB-SG-In" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["10.0.2.0/24", "10.0.4.0/24"]

  security_group_id = aws_security_group.DB-SG.id

}

# DB-SG 아웃바운드 규칙 추가 #
resource "aws_security_group_rule" "DB-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.DB-SG.id
}

# DB subnet 생성 #
resource "aws_db_subnet_group" "DB-Subnet" {
  name = "db-subnet"
  subnet_ids = [
    "${aws_subnet.Private-Subnet1.id}",
    "${aws_subnet.Private-Subnet2.id}"
  ]
  tags = {
    Name = "DB-Subnet"
  }
}

# mariadb 기반 인스턴스 생성, 다중AZ 배포, storage auto scaling 
resource "aws_db_instance" "Project-DB" {
  identifier             = "project-db" #=> aws에서 보이는 rds 이름
  allocated_storage      = 20
  max_allocated_storage  = 40
  engine                 = "mariadb"
  engine_version         = "10.6.5"
  instance_class         = "db.t2.micro"
  db_name                = "projectdb" #=> db자체 이름
  username               = "root"
  password               = "mypass123" #=>비번 8자 이상
  apply_immediately      = "true"
  parameter_group_name   = aws_db_parameter_group.pg_mariadb10_6.name
  db_subnet_group_name   = aws_db_subnet_group.DB-Subnet.name
  vpc_security_group_ids = ["${aws_security_group.DB-SG.id}"]
  skip_final_snapshot    = true
  multi_az               = true
  storage_type           = "gp2"

}

# 한글깨짐 방지, 타임존 설정
resource "aws_db_parameter_group" "pg_mariadb10_6" {
  name        = "db-pg"
  description = "Terraform declare parameter group for mariadb10.6"
  family      = "mariadb10.6"
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_filesystem"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_connection"
    value = "utf8mb4_general_ci"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_general_ci"
  }
  parameter {
    name  = "time_zone"
    value = "asia/seoul"
  }
}


#################### DMS SG 생성 ####################
resource "aws_security_group" "DMS-SG" {
  vpc_id = aws_vpc.Project-VPC.id
  name   = "DMS-SG"

  tags = {
    Name = "DMS-SG"
  }
}

# DMS SG 인바운드 규칙 추가 #
resource "aws_security_group_rule" "DMS-SG-In" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["10.0.1.0/24", "10.0.3.0/24"]

  security_group_id = aws_security_group.DMS-SG.id

}

# DMS SG 아웃바운드 규칙 추가 #
resource "aws_security_group_rule" "DMS-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.DMS-SG.id
}