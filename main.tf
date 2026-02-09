# --- PROVIDERS ---
provider "aws" {
  region = "us-east-1" 
}

# This lets Terraform talk to your local k3d cluster
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# --- NETWORKING: The IP Pinhole ---
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "rds_sg" {
  name        = "k3d-to-rds-sg"
  description = "Allow local laptop to reach RDS"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }
}

# --- DATABASE: The Managed State ---
resource "aws_db_instance" "postgres" {
  allocated_storage      = 10
  engine                = "postgres"
  engine_version        = "15"
  instance_class        = "db.t3.micro" # Free Tier!
  db_name               = "hybrid_db"
  #username              = "dbadmin"
  #password              = "BitchProofPassword123" # We will move this to a secret later
  
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}
resource "kubernetes_secret_v1" "db_connection" {
  metadata {
    name      = "rds-db-config"
    namespace = "default"
  }

  data = {
    # We are pulling the data directly from the AWS resource we just created!
    DB_HOST     = aws_db_instance.postgres.address
    DB_USER     = aws_db_instance.postgres.username
    DB_PASSWORD = aws_db_instance.postgres.password
    DB_PORT     = aws_db_instance.postgres.port
  }
}

resource "kubernetes_pod_v1" "db_tester" {
  metadata {
    name = "rds-tester"
  }

  spec {
    container {
      name  = "tester"
      image = "postgres:15" # We use the postgres image because it has the 'psql' tool built in
      
      # This is how you pass the AWS info into the container
      env {
        name = "DB_HOST"
        value_from {
          secret_key_ref {
            name = "rds-db-config"
            key  = "DB_HOST"
          }
        }
      }

      # We just want the pod to stay alive so we can log into it
      command = ["sleep", "3600"]
    }
  }
}

# 1. Create the IAM User for Grafana
resource "aws_iam_user" "grafana_monitor" {
  name = "grafana-cloudwatch-reader"
}

# 2. Create the Access Key (We will teleport this to k3d too!)
resource "aws_iam_access_key" "grafana_key" {
  user = aws_iam_user.grafana_monitor.name
}

# 3. Create the Policy to allow reading metrics
resource "aws_iam_user_policy" "grafana_cw_policy" {
  name = "GrafanaCloudWatchPolicy"
  user = aws_iam_user.grafana_monitor.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    {
        # Logs Permissions (The missing piece!)
        Sid    = "AllowReadingLogsFromCloudWatch"
        Action = [
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        # Tag Permissions (Helps Grafana find resources by name)
        Sid    = "AllowReadingTags"
        Action = [
          "tag:GetResources",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }  
    ]
  })
}

resource "kubernetes_secret_v1" "grafana_aws_creds" {
  metadata {
    name = "grafana-aws-credentials"
  }

  data = {
    access_key_id     = aws_iam_access_key.grafana_key.id
    secret_access_key = aws_iam_access_key.grafana_key.secret
  }
}
