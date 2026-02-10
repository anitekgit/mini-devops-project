## AWS Region ##

variable "region_id" {
    description = "Deployment Region"
    type = string
}

## VPC Configuration ##

variable "vpc_name" {
    description = "VPC Name"
    type = string
}

variable "vpc_cidr" {
    description = "VPC CIDR"
    type = string
}

variable "private-subnet-1" {
    description = "Subnet CIDR"
    type = string
}

variable "private-subnet-2" {
    description = "Subnet CIDR"
    type = string
}

variable "public-subnet-1" {
    description = "Subnet CIDR"
    type = string
}

variable "public-subnet-2" {
    description = "Subnet CIDR"
    type = string
}

variable "ami-id" {
    description = "AMI ID"
    type = string
}

variable "instance-type" {
    description = "Instance Type"
    type = string
}

variable "key-name" {
    description = "Key Name"
    type = string
}

variable "eks-name" {
    description = "EKS Cluster Name"
    type = string
}


variable "disk-size" {
    description = "Disk Size"
    type = string
}

variable "ami-type" {
    description = "EKS Node AMI ID"
    type = string
}

variable "eks-instance-type" {
    description = "EKS Instance Type"
    type = string
}

variable "eks-version" {
    description = "EKS Version"
    type = string
}

variable "des-nodes" {
    description = "Desired number of nodes"
    type = string
}

variable "max-nodes" {
    description = "Maximum number of nodes"
    type = string
}

variable "min-nodes" {
    description = "Minimum number of nodes"
    type = string
}

variable "ecr-name" {
    description = "ECR Name"
    type = string
}
