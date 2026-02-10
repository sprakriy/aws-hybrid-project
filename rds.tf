resource "aws_security_group" "rds_sg" {
  name        = "k3d-to-rds-sg"
  description = "Allow VPN and local laptop to reach RDS"

  # Rule for the VPN (This is what k3d will use)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.200.0.0/22"] # The VPN range we defined earlier
  }
  /*
  # Keep your current IP rule as a "backup" if you want to connect without VPN
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  }
  */

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "15.4" # Specific versions are safer for Terraform
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  db_name                = "hybrid_db"
  
  # Set these to false to act like a real private corporate DB
  publicly_accessible    = false 
  
  # Ensure it lands in the correct VPC subnets
  # db_subnet_group_name = aws_db_subnet_group.main.name 

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}