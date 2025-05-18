# project for secure s3 and ec2 setup
This repo contains a minimal and secure Terraform setup that deploys:
- An EC2 instance inside a private subnet (no public IP)
- An encrypted, versioned S3 bucket with public access blocked

The main focus is to follow AWS security best practices and avoid common misconfigurations.

---

## ✅ What This Does

- Creates a VPC with both public and private subnets
- Deploys an EC2 instance in the **private** subnet
- Sets up a **NAT gateway** for outbound internet access
- Creates a secure S3 bucket with:
  - Versioning enabled
  - Encryption using a custom KMS key
  - Public access completely blocked
- Assigns a **least privilege IAM role** to the EC2 instance (read-only S3 access)
- Uses security groups to limit SSH access (only allowed within the VPC)

---

