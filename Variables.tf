
variable "vpc_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The provided CIDR block is not valid."
  }
}
variable "bucketname" {
  type = string
  validation {
    condition     = length(var.bucketname) >= 3 && length(var.bucketname) <= 63
    error_message = "Bucket name must be between 3 and 63 characters long."
  }
}
variable "private_subnet_cidr" {}
variable "public_subnet_cidr" {}


