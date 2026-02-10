# main.tf

################################################### Network Setup ###########################################################

################ VPC Deploy ##################
resource "aws_vpc" "isengard-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

############### Subnet Deploy #################
resource "aws_subnet" "private-subnet-1" {
  vpc_id = aws_vpc.isengard-vpc.id
  cidr_block = var.private-subnet-1
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = aws_vpc.isengard-vpc.id
  cidr_block = var.private-subnet-2
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.isengard-vpc.id
  cidr_block = var.public-subnet-1
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = aws_vpc.isengard-vpc.id
  cidr_block = var.public-subnet-2
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-subnet-2"
  }
}

############### IGW & NAT ##################
resource "aws_internet_gateway" "isengard-igw" {
  vpc_id = aws_vpc.isengard-vpc.id
  tags = {
    Name = "isegard-igw"
  }
}

resource "aws_eip" "nat-eip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "isengard-nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id = aws_subnet.public-subnet-1.id
  tags = {
    Name = "isengard-nat"
  }
}

############### Route Table ################
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.isengard-vpc.id
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.isengard-vpc.id
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route" "private-route" {
  route_table_id = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.isengard-nat.id
}

resource "aws_route" "public-route" {
  route_table_id = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.isengard-igw.id
}

locals {
  private_subnet = {
    sub1 = aws_subnet.private-subnet-1.id
    sub2 = aws_subnet.private-subnet-2.id
  }

  public_subnet = {
    sub3 = aws_subnet.public-subnet-1.id
    sub4 = aws_subnet.public-subnet-2.id
  }
}

resource "aws_route_table_association" "private-rt-association" {
  for_each = local.private_subnet
  subnet_id = each.value
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "public-rt-association" {
  for_each = local.public_subnet
  subnet_id = each.value
  route_table_id = aws_route_table.public-rt.id
}

##################################################### EC2 Setup #############################################################

resource "aws_security_group" "isengard-sg" {
  name = "isengard-aws"
  description = "Common SG"
  vpc_id = aws_vpc.isengard-vpc.id
tags = {
  Name = "isengard-sg"
}

ingress {
  description = "SSH"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {

  description = "SSH"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

}

resource "aws_instance" "isengard-vm" {
  ami = var.ami-id
  vpc_security_group_ids = [aws_security_group.isengard-sg.id]
  associate_public_ip_address = true
  instance_type = var.instance-type
  subnet_id = aws_subnet.public-subnet-1.id
  key_name = var.key-name

tags = {
  Name = "isengard-vm"
}

}

##################################################### EKS Setup #############################################################

# IAM Roles for Clutser and Node Group
resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
        Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iam-policy-attachment" {
  role = aws_iam_role.eks-cluster-role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node-role" {
  name = "node-role"
  assume_role_policy = jsonencode({
        Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
locals {
  node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "eks-node-policy-attach" {
  for_each   = toset(local.node_policies)
  role       = aws_iam_role.node-role.name
  policy_arn = each.value
}

# EKS Cluster
resource "aws_eks_cluster" "isengard-eks-cluster" {
  name = var.eks-name
  role_arn = aws_iam_role.eks-cluster-role.arn
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
  version = var.eks-version
  vpc_config {
    subnet_ids = [
      aws_subnet.private-subnet-1.id,
      aws_subnet.private-subnet-2.id
    ]
  }
}

# EKS Node Group
resource "aws_eks_node_group" "isengard-node-group" {
  cluster_name = var.eks-name
  node_group_name = "${var.eks-name}-nodegroup"
  disk_size = var.disk-size
  ami_type = var.ami-type
  instance_types = [var.eks-instance-type]
  remote_access {
    ec2_ssh_key = var.key-name
    source_security_group_ids = [aws_security_group.isengard-sg.id]
  }
  scaling_config {
    desired_size = var.des-nodes
    max_size = var.max-nodes
    min_size = var.min-nodes
  }
  node_role_arn = aws_iam_role.node-role.arn
  subnet_ids = [
    aws_subnet.private-subnet-1.id,
    aws_subnet.private-subnet-2.id
  ]
  depends_on = [ 
    aws_eks_cluster.isengard-eks-cluster
   ]
}

##################################################### ECR Setup #############################################################

resource "aws_ecr_repository" "isengard-ecr" {
  name = var.ecr-name
}

############################################################################################################################
#############################################   End of script  #############################################################
############################################################################################################################
