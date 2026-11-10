terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "ap-southeast-2"
}
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/26.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}
data "aws_caller_identity" "current" {}
resource "aws_iam_role" "app_ec2_role" {
  name = "booknest-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_ecr_read" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "app_cloudwatch" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "booknest-app-instance-profile"
  role = aws_iam_role.app_ec2_role.name
}
# Create the key pair
resource "tls_private_key" "datacenter_kp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "datacenter_kp" {
  key_name   = "datacenter-kp"
  public_key = tls_private_key.datacenter_kp.public_key_openssh
}

# Save the private key to file
resource "local_file" "private_key" {
  content         = tls_private_key.datacenter_kp.private_key_pem
  filename        = "/home/lenovo/Downloads/little-things-club-static-website/key/datacenter-kp.pem"
  file_permission = "0400"
}

# Output the key pair name (optional)
output "key_pair_name" {
  value = aws_key_pair.datacenter_kp.key_name
}
resource "aws_vpc" "wb_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "wb_subnet" {
  vpc_id            = aws_vpc.wb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "wb_subnet2" {
  vpc_id            = aws_vpc.wb_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_instance" "jenkins_cr" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t8i.micro"
  key_name                    = aws_key_pair.datacenter_kp.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.wb_subnet2.id
  tags = {
    Name = "jenkins-controller"
  }
  user_data = <<-EOF
  #!/bin/bash
  set -eux

  # Update Ubuntu
  apt-get update -y

  # Install Java 21 (Jenkins runtime)
  apt-get install -y fontconfig openjdk-21-jre curl wget gnupg awscli docker.io

  # Install Jenkins LTS
  install -d -m 0755 /usr/share/keyrings

  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /usr/share/keyrings/jenkins-keyring.asc

  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

  apt-get update -y
  apt-get install -y jenkins

  # Start Docker
  systemctl enable docker
  systemctl start docker

  # Allow Jenkins to execute Docker commands
  usermod -aG docker jenkins

  # Enable Jenkins at startup
  systemctl enable jenkins
  systemctl restart jenkins

EOF
}

resource "aws_subnet" "rd_subnet3" {
  vpc_id            = aws_vpc.wb_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "private-subnet-3"
  }
}
resource "aws_subnet" "rd_subnet4" {
  vpc_id            = aws_vpc.wb_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "private-subnet-4"
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.wb_vpc.id

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

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.wb_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    cidr_blocks     = ["178.93.83.50/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.wb_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["178.93.83.50/32"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["178.93.83.50/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_internet_gateway" "wb_igw" {
  vpc_id = aws_vpc.wb_vpc.id
}
resource "aws_route_table" "wb_route_table" {
  vpc_id = aws_vpc.wb_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wb_igw.id
  }
}
resource "aws_route_table_association" "wb_route_table_assoc" {
  subnet_id      = aws_subnet.wb_subnet.id
  route_table_id = aws_route_table.wb_route_table.id
}

resource "aws_route_table_association" "wb_route_table_assoc2" {
  subnet_id      = aws_subnet.wb_subnet2.id
  route_table_id = aws_route_table.wb_route_table.id
}

resource "aws_route_table" "rds_rt" {
  vpc_id = aws_vpc.wb_vpc.id

  tags = {
    Name = "private-db-route-table"
  }
}
resource "aws_route_table_association" "rds_assoc1" {
  subnet_id      = aws_subnet.rd_subnet3.id
  route_table_id = aws_route_table.rds_rt.id
}

resource "aws_route_table_association" "rds_assoc2" {
  subnet_id      = aws_subnet.rd_subnet4.id
  route_table_id = aws_route_table.rds_rt.id
}

resource "aws_security_group" "rds_ingress" {
  name        = "rds_ingress"
  description = "Allow MySQL access from the VPC"
  vpc_id      = aws_vpc.wb_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_db_subnet_group" "wb_db_subnet_group" {
  name       = "wb_db_subnet_group"
  subnet_ids = [aws_subnet.rd_subnet3.id, aws_subnet.rd_subnet4.id]
}

resource "aws_db_instance" "wb_rds" {
  allocated_storage     = 20
  engine                = "postgres"
  engine_version        = "18.6"
  instance_class        = "db.t3.micro"
  storage_type          = "gp3"
  copy_tags_to_snapshot = true

  username               = "booknest_admin"
  password               = "Booknest123#" # Replace with a secure password
  db_subnet_group_name   = aws_db_subnet_group.wb_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_ingress.id]

  publicly_accessible       = false
  multi_az                  = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "booknest-final-snapshot"
}
resource "aws_db_snapshot" "booknest_snapshot" {
  db_instance_identifier = aws_db_instance.wb_rds.identifier
  db_snapshot_identifier = "booknest-manual-snapshot"

  tags = {
    Name        = "booknest-manual-snapshot"
    Environment = "dev"
  }
}
resource "aws_lb" "wb_alb" {
  name               = "wb-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.wb_subnet.id, aws_subnet.wb_subnet2.id]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "wb_target_group" {
  name     = "wb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wb_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "wb_listener" {
  load_balancer_arn = aws_lb.wb_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wb_target_group.arn
  }
}

resource "aws_launch_template" "wb_launch_template" {
  name_prefix   = "wb-launch-template-"
  image_id      = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t8i.micro"
  key_name      = aws_key_pair.datacenter_kp.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance_profile.name
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -euxo pipefail

  # Install Docker and AWS CLI
  apt-get update -y
  apt-get install -y docker.io awscli wget curl

  systemctl enable docker
  systemctl start docker

  # Discover AWS account and region
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

  AWS_REGION=$(curl -s \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/region)

  ACCOUNT_ID=$(aws sts get-caller-identity \
    --query Account --output text --region "$AWS_REGION")

  ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

  # Authenticate with ECR using EC2 instance role
  aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$ECR_REGISTRY"

  # Create Docker network if it doesn't exist
  docker network inspect booknest-network >/dev/null 2>&1 || \
    docker network create booknest-network

  # Pull application images
  docker pull "$ECR_REGISTRY/booknest-backend:latest"
  docker pull "$ECR_REGISTRY/booknest-frontend:latest"

  # Remove old containers if present
  docker rm -f booknest-frontend booknest-backend || true

  # Start backend
  docker run -d \
    --name booknest-backend \
    --network booknest-network \
    --restart unless-stopped \
    "$ECR_REGISTRY/booknest-backend:latest"

  # Start frontend
  docker run -d \
    --name booknest-frontend \
    --network booknest-network \
    -p 8081:80 \
    --restart unless-stopped \
    "$ECR_REGISTRY/booknest-frontend:latest"

  # Install CloudWatch Agent
  cd /tmp
  wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i -E ./amazon-cloudwatch-agent.deb

  # Configure CloudWatch metrics
  cat <<'CONFIG' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  {
    "metrics": {
      "namespace": "BookNest/EC2",
      "metrics_collected": {
        "mem": {
          "measurement": ["mem_used_percent"]
        },
        "disk": {
          "measurement": ["used_percent"],
          "resources": ["/"]
        }
      }
    }
  }
  CONFIG

  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wb-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "wb_asg" {
  desired_capacity    = 4
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.wb_subnet.id, aws_subnet.wb_subnet2.id]
  target_group_arns   = [aws_lb_target_group.wb_target_group.arn]
  launch_template {
    id      = aws_launch_template.wb_launch_template.id
    version = "$Latest"
  }
}


#ecr

resource "aws_ecr_repository" "booknest_frontend" {
  name                 = "booknest-frontend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_repository" "booknest_backend" {
  name                 = "booknest-backend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "frontend_policy" {
  repository = aws_ecr_repository.booknest_frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = {
        type = "expire"
      }
    }]
  })
}
output "frontend_ecr_url" {
  value = aws_ecr_repository.booknest_frontend.repository_url
}

output "backend_ecr_url" {
  value = aws_ecr_repository.booknest_backend.repository_url
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/booknest/application"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "apache_logs" {
  name              = "/booknest/apache"
  retention_in_days = 30
}

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "booknest-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "booknest-ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}


resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "booknest-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wb_asg.name
  }

  alarm_description = "Average ASG instance CPU is above 80%"
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "booknest-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    LoadBalancer = aws_lb.wb_alb.arn_suffix
  }

  alarm_description = "ALB is returning more than 5 server errors"
}


resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "booknest-no-healthy-targets"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.wb_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.wb_target_group.arn_suffix
  }

  alarm_description = "No healthy application targets are available"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "booknest-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.wb_rds.identifier
  }

  alarm_description = "RDS CPU utilization is above 80%"
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "booknest-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Minimum"
  threshold           = 2000000000

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.wb_rds.identifier
  }

  alarm_description = "RDS free storage is below 2 GB"
}


variable "alarm_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}

resource "aws_sns_topic" "booknest_alerts" {
  name = "booknest-cloudwatch-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.booknest_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}


