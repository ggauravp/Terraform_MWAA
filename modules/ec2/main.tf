resource "aws_instance" "postgres_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  tags = {
    Name        = "postgres-ec2"
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow Postgres access from Lambda"
  vpc_id      = data.aws_vpc.default.id

# Allow Postgres access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks 
  }

# Allow SSH access
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_cidr_blocks 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "postgres-sg"
    Environment = var.environment
  }
}
