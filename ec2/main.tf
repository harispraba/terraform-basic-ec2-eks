terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 4.16"
        }
    }

    required_version = ">= 1.2.0"
}

provider "aws" {
    region  = "ap-southeast-1"
}

locals {
    instance = {
        instance_type = var.instance.instance_type
        ami = var.instance.ami
        public_key = var.instance.public_key
    }
}

resource "aws_key_pair" "key_setup" {
    public_key = local.instance.public_key
}

resource "aws_vpc" "vpc_setup" {
    cidr_block = "10.3.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "vpc-setup"
    }
}

# Create 3 subnets
resource "aws_subnet" "subnet_1" {
    cidr_block = "10.3.1.0/24"
    vpc_id = "${aws_vpc.vpc_setup.id}"
    availability_zone = "ap-southeast-1a"
    map_public_ip_on_launch = "true"
}
resource "aws_subnet" "subnet_2" {
    cidr_block = "10.3.2.0/24"
    vpc_id = "${aws_vpc.vpc_setup.id}"
    availability_zone = "ap-southeast-1b"
    map_public_ip_on_launch = "true"
}
resource "aws_subnet" "subnet_3" {
    cidr_block = "10.3.3.0/24"
    vpc_id = "${aws_vpc.vpc_setup.id}"
    availability_zone = "ap-southeast-1c"
    map_public_ip_on_launch = "true"
}

resource "aws_security_group" "secgroup_setup" {
    name = "allow-ssh"
    
    vpc_id = "${aws_vpc.vpc_setup.id}"
    
    ingress {
        description = "Allow ssh from anywhere"
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 22
        to_port = 22
        protocol = "tcp"
    }
    
    ingress {
        description = "Allow http from anywhere"
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 80
        to_port = 80
        protocol = "tcp"
    }
    
    ingress {
        description = "Allow TLS from anywhere"
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 443
        to_port = 443
        protocol = "tcp"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_internet_gateway" "gateway_setup" {
    vpc_id = "${aws_vpc.vpc_setup.id}"
    
    tags = {
        Name = "inet-gateway"
    }
}

resource "aws_route_table" "route_table_setup" {
    vpc_id = "${aws_vpc.vpc_setup.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway_setup.id}"
    }
    tags = {
        Name = "route-table-1"
    }
}

# Associate subnet with route table
resource "aws_route_table_association" "subnet_1_association" {
    subnet_id      = "${aws_subnet.subnet_1.id}"
    route_table_id = "${aws_route_table.route_table_setup.id}"
}
resource "aws_route_table_association" "subnet_2_association" {
    subnet_id      = "${aws_subnet.subnet_2.id}"
    route_table_id = "${aws_route_table.route_table_setup.id}"
}
resource "aws_route_table_association" "subnet_3_association" {
    subnet_id      = "${aws_subnet.subnet_3.id}"
    route_table_id = "${aws_route_table.route_table_setup.id}"
}

resource "aws_launch_template" "launch_template" {
    name_prefix             = "terraform"
    image_id                = local.instance.ami
    instance_type           = local.instance.instance_type
    user_data               = file("userdata/init.sh")
    vpc_security_group_ids  = [aws_security_group.secgroup_setup.id]
    key_name                = aws_key_pair.key_setup.key_name
}

resource "aws_autoscaling_group" "asg_1" {
    # availability_zones    = ["ap-southeast-1"]
    desired_capacity      = 2
    max_size              = 3
    min_size              = 1
    vpc_zone_identifier   = [aws_subnet.subnet_1.id,
                             aws_subnet.subnet_2.id,
                             aws_subnet.subnet_3.id]

    launch_template {
        id      = aws_launch_template.launch_template.id
        version = "$Latest"
    }
}

output "subnet_1" {
    value       = aws_subnet.subnet_1.id
}

output "subnet_2" {
    value       = aws_subnet.subnet_2.id
}

output "subnet_3" {
    value       = aws_subnet.subnet_3.id
}