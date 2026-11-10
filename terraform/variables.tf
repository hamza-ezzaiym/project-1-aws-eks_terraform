variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Short resource prefix"
  type        = string
  default     = "devops-demo"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version supported by the selected region"
  type        = string
  default     = "1.33"
}

variable "instance_types" {
  description = "EC2 types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired worker count"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum worker count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum worker count"
  type        = number
  default     = 3
}
