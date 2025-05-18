# 🚀 Project: Secure S3 and EC2 Setup

This repo contains a **minimal and secure Terraform setup** that deploys:
- An EC2 instance inside a private subnet (no public IP)
- An encrypted, versioned S3 bucket with public access blocked

The main focus is to follow **AWS security best practices** and avoid common misconfigurations.

---

## ✅ What This Setup Does

- Creates a **VPC** with both public and private subnets
- Deploys an **EC2 instance** in the **private** subnet (no internet-facing IP)
- Sets up a **NAT Gateway** to allow private subnet instances to reach the internet (e.g., for package installation)
- Creates a secure **S3 bucket** with:
  - ✅ Versioning enabled
  - 🔐 Encryption using a custom **KMS** key
  - 🚫 Public access completely blocked
- Assigns a **least privilege IAM role** to the EC2 instance (read-only access to S3)
- Defines **Security Groups** to restrict SSH access (only within the VPC)

---

## 🔒 Security Best Practices Implemented

- ❌ No hardcoded AWS credentials or secrets
- ✅ IAM roles used for EC2 instance
- ✅ Principle of Least Privilege (S3 read-only access)
- ✅ Server-side encryption for S3
- ✅ Public access fully blocked on the bucket
- ✅ Private subnet for EC2 instance
- ✅ NAT Gateway used for controlled outbound traffic
- ✅ Security groups scoped appropriately

---

## 🔍 Variable Validations (Terraform)

To ensure input safety and catch misconfigurations early, this project includes **Terraform variable validations**:

### 📌 S3 Bucket Name Validation
```hcl
variable "bucket_name" {
  type = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters long."
  }
}
