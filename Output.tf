output "aws_s3_bucket" {
  value = aws_s3_bucket.secure_bucket.bucket
}
output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}
output "private_instance_ip" {
  value = aws_instance.private.private_ip
}
