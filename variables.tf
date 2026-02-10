# variables.tf

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "rds_subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
  default     = ["subnet-005676b0cd928bdc1", "subnet-0a1a0a282ea266887"]
}