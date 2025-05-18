# Problems and Solutions

These are the issues I faced while building this Terraform setup and how I solved them:

---

### 1. EC2 Instance Did Not Have Internet Access

**Problem:**  
When I first deployed the EC2 instance, I assumed it would work inside a private subnet. However, it couldn't access the internet — no software updates, and S3 access failed as well.

**Solution:**  
I realized a NAT Gateway is needed for private subnets to have outbound internet access. To fix this:
- I added an Internet Gateway (IGW) and a public subnet.
- Created a NAT Gateway in the public subnet.
- Updated the private subnet’s route table to route `0.0.0.0/0` traffic through the NAT.

This allowed the EC2 instance to access the internet without being exposed to inbound traffic.

---

### 2. Delayed IAM Role Policy Attachment

**Problem:**  
I created an IAM role and attached a custom S3 read-only policy. Everything looked correct, but the EC2 instance still couldn’t access the S3 bucket.

**Solution:**  
I mistakenly assumed that just defining the role and policy was enough. In reality, they must be **explicitly attached** using the `aws_iam_role_policy_attachment` resource.

After I added this resource to connect the policy to the EC2 role, access to the S3 bucket worked as expected.

---

### 3. S3 Bucket Name Conflict

**Problem:**  
S3 bucket names must be globally unique. I initially hardcoded a bucket name, which caused issues when reapplying or sharing the code.

**Solution:**  
I used Terraform’s `random_id` resource to append a random 4-byte hex suffix to the bucket name. This ensures each deployment has a unique, conflict-free bucket name:

```hcl
bucket = "project-bucket-${random_id.bucket_id.hex}"
