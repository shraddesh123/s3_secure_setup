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
## ✅ Step 1: Generate SSH Key Pair

Generate an SSH key pair on your local machine:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/main-key
```

This creates:

- `~/.ssh/main-key` (private key)
- `~/.ssh/main-key.pub` (public key)

---

## ✅ Step 2: Use Public Key in Terraform

Reference the public key in your Terraform configuration:

```hcl
resource "aws_key_pair" "kp" {
  key_name   = "main-key"
  public_key = file("~/.ssh/main-key.pub")
}
```

---

## ✅ Step 3: Initialize and Deploy

Run the following to initialize and deploy your infrastructure:

```bash
terraform init
terraform apply
```

Approve the plan when prompted.

---

## ✅ Step 4: Copy Private Key to Bastion (Public EC2)

Get the public EC2 IP:

```bash
terraform output public_instance_ip
```

Then copy the private key to the bastion host:

```bash
scp -i ~/.ssh/main-key ~/.ssh/main-key ec2-user@<public_instance_ip>:~/main-key.pem
```

Replace `<public_instance_ip>` with the actual IP.

---

## ✅ Step 5: SSH Into Public EC2

SSH into the bastion host:

```bash
ssh -i ~/.ssh/main-key ec2-user@<public_instance_ip>
```

Once inside, set appropriate permissions on the key:

```bash
chmod 400 main-key.pem
```

---

## ✅ Step 6: SSH Into Private EC2

Get the private EC2 IP:

```bash
terraform output private_instance_ip
```

From the public EC2, connect to the private EC2:

```bash
ssh -i main-key.pem ec2-user@<private_instance_ip>
```

---

## 🧼 Cleanup

To destroy all created resources:

```bash
terraform destroy
```
