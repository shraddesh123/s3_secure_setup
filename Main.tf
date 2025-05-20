//VPC
resource "aws_vpc" "Main_vpc" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "main-vpc" }
}
//Private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.Main_vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags                    = { Name = "private-subnet" }
}
//internet gateway to access the internet via nat gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Main_vpc.id
}
//public subnet which has internet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.Main_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet" }
}
//static ip for nat gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}
//nat gateway for private instance 
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
}
// for connection between public_subnet and igw
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.Main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}
//public subnet association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
//for connection between private_subnet and natgw
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.Main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = { Name = "private-rt" }
}
//private subnet association
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

#Security Group 

resource "aws_security_group" "private_sg" {
  name        = "ec2-private-sg"
  description = "Allow SSH from a bastion or VPN only"
  vpc_id      = aws_vpc.Main_vpc.id

  # No ingress from the internet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Only allow SSH from within VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" //all traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-private-sg" }
}

#IAM role and policy for EC2 with least privilege

data "aws_iam_policy_document" "ec2_s3_readonly" {
  statement {
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.secure_bucket.arn,
      "${aws_s3_bucket.secure_bucket.arn}/*"
    ]
  }
}
//ec2 role for s3
resource "aws_iam_role" "ec2" {
  name = "ec2-s3-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ec2_s3_readonly" {
  name   = "ec2-s3-readonly"
  policy = data.aws_iam_policy_document.ec2_s3_readonly.json
}
// attaching the policy
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_s3_readonly.arn
}
// ec2 instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-s3-readonly-profile"
  role = aws_iam_role.ec2.name
}
//random suffix for uniqueness
resource "random_id" "bucket_id" {
  byte_length = 4
}
#S3 Bucket 
resource "aws_s3_bucket" "secure_bucket" {
  bucket        = "${var.bucketname}${random_id.bucket_id.hex}"
  force_destroy = true
  tags          = { Name = "secure-bucket" }
}
//versioning for the bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
//kms key for the encryption
resource "aws_kms_key" "s3" {
  enable_key_rotation = true
}
//s3 server_side_encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}
//blocks all pubic access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#EC2 Instance in Private Subnet 

resource "aws_instance" "private" {
  ami                         = "ami-0c94855ba95c71c99" #us-east-1
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = aws_key_pair.kp.key_name

  # No hardcoded secrets; use IAM role for AWS access
  tags = { Name = "private-ec2" }
}
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.Main_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "public_sg" }
}
resource "aws_key_pair" "kp" {
  key_name   = "main-key"
  public_key = file("C:/Users/Asus/Downloads/my-key.pem")
}
resource "aws_instance" "public_instance" {
  ami                         = "ami-0c94855ba95c71c99"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.kp.key_name
}
output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}

output "private_instance_ip" {
  value = aws_instance.private.private_ip
}
