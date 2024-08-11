# variables.tf
variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "availability_zone" {
  description = "The availability zone for the resources"
  type        = string
  default     = "us-east-1a"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
}
