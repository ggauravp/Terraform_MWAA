resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = var.bucket_name
  
  tags = {
    Name        = "mwaa_bucket"
    Environment = var.environment
  }
}