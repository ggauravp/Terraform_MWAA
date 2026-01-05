resource "aws_iam_role" "this" {
  name = var.role_name # IAM role name passed from module call

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = var.service_principal #can be "lambda.amazonaws.com" or "airflow.amazonaws.com" depending on the role being created
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
