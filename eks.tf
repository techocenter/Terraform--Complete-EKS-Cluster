provider "aws"{
    region "us-east-1"
    #version ="**"
}
# IAM role for making calls to other AWS services
resource "aws_iam_role" "eks-cluster-iam-role" {
    name = "sample eks cluster"
    assume_role_policy =<< 
    {
        "Version": "2012-02-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service":"eks.amazonaws.com",
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
    POLICY
}

# attach eks cluster and service policies to eks iam role
resource "aws_iam_role_policy_attachment" "eks-cluster-policy-attach" {
    policy_arn = "arn:aws:iam:aws:policy/AmazonEKSClusterPolicy"
    role="${aws_iam_role.eks-cluster-iam-role.name}"
}
resource "aws_iam_role_policy_attachment" "eks-service-policy-attach" {
    policy_arn = "arn:aws:iam:aws:policy/AmazonEKServicePolicy"
    role="${aws_iam_role.eks-cluster-iam-role.name}"
}

# eks cluster network security group
resource "aws_security_group" "sample-eks-cluster-sg" {
    name   = "Sample EKS Cluster SG"
    vpc_id ="vpc-************"
    # Security group outbound rule
    egress {
        from_port = 0
        to_port   = 0
        protocol = "-1"
        cidr_blocks=["0.0.0.0/0"]
    }
    # Security group inbound rule
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks=["0.0.0.0/0"]
    }
}

# Creating Sample EKS Cluster
resource "aws_eks-cluster" "sample-eks-cluster" {
    name = "sample eks cluster"
    role_arn = "${aws_iam_role.eks-cluster-iam-role.arn}"
    version = "1.19"

    # VPC configuration for Sample EKS Cluster
    vpc_config {
        security_group_ids=["${aws_security_group.sample-eks-cluster-sg.id}"]
        subnet_ids =[ "subent-*******", "subnet-*******"]
    }

    depends_on = [
        "aws_iam_role_policy_attachment.eks-cluster-policy-attach",
        "aws_iam_role_policy_attachment.eks-service-policy-attach",
    ]
}

# IAM EKS Nodes role to work with other services
resource "aws_iam_role" "sample-eks-nodes-role" {
    name = "sample eks cluster nodes role"
    assume_role_policy =<<POLICY 
    {
        "Version": "2012-10-17",
        "Statement" : [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service":"ec2.amazonaws.com"
                },
                "Action":"sts:AssumeRole"
            }
        ]
    }
    POLICY
}

# attach multiple policies to eks nodes
resource "aws_iam_role_policy_attachment" "sample-eks-cni-policy" {
    policy_arn = "arn:aws:iam:aws:policy/AmazonEKS_CNI_Policy"
    role_arn =aws_iam_role.sample-eks-nodes-role.name
}
resource "aws_iam_role_policy_attachment" "sample-eks-workernode-policy"{
    policy_arn = "arn:aws:iam:aws:policy/AmazonEKSWorkerNodePolicy"
    role_arn =aws_iam_role.sample-eks-nodes-role.name
}
resource "aws_iam_role_policy_attachment" "samle-eks-ECR-readonly-policy" {
    policy_arn = "arn:aws:iam:aws:policy/AmazonEC2ContainerRegisteryReadOnly"
    role_arn =aws_iam_role.sample-eks-nodes-role.name
}

# create Sample EKS Cluster Node Group
resource "aws_eks_node_group" "sample-eks-cluster-nodegroup" {
    cluster_name = "aws_eks_cluster.sample-eks-cluster.name"
    node_group_name="group1"
    node_role_arn= aws_iam_role.sample-eks-nodes-role.arn
    subnet_ids = ["subent-******", "subnet-******"]
    
    scaling_config {
        desired_size    =1
        max_size        =2
        min_size        =1
    }
    depends_on = [
        aws_iam_role_policy_attachment.sample-eks-cni-policy,
        aws_iam_role_policy_attachment.sample-eks-workernode-policy,
        aws_iam_role_policy_attachment.sample-eks-ECR-readonly-policy
    ]
}