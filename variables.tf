variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "my_ip" {
  description = "Your local IP for SSH access (e.g., '1.2.3.4/32')"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Open to all. Change this!
}

# Find Ubuntu AMIs in your region
variable "ubuntu_22_04_ami" {
  description = "AMI for Ubuntu 22.04"
  type        = string
  default     = "ami-053b0d53c279acc90" # us-east-1 Ubuntu 22.04
}

variable "ubuntu_20_04_ami" {
  description = "AMI for Ubuntu 20.04"
  type        = string
  default     = "ami-04a0ae173da5807d3" # us-east-1 Ubuntu 20.04
}
