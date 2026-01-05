output "my_bucket_arn" {
    value = aws_s3_bucket.mwaa_bucket.arn
}

output "bucket_name" {
    value = aws_s3_bucket.mwaa_bucket.bucket
}