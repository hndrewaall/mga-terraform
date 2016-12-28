# Provider
provider "aws" { region = "us-east-1" }


# Data sources
data "terraform_remote_state" "s3" {
    backend = "s3"
    config
    {
        bucket = "${aws_s3_bucket.tfstate.bucket}"
        key = "terraform.tfstate"
        region = "us-east-1"
    }
}

# Key Pair
resource "aws_key_pair" "massgo_ec2" {
  key_name = "massgo_ec2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDf00N/1TcPvHF+FpQFzkijmSQecvk5IoyoCkSF6JA1KJ0hZU5f3sR56Bp9aZyDJlHFGnOSKAchTHDhU75uSTF3aSWVy3b2Qd+Fvmf9QY9OHiHOkHmmoQtrvep8/SHIVRUyjQWdSGNFF3sXdx/i7Qdgaa97jn60+/2QKmo7JV2CtAtyAa7dvYQIm6Gj4z9L72Ca5MTYAaRselcpFpbI9QEaSi4FqrM13GiW7jhX64rbTIzgtxkFgGzDMUo7gehBLqoCTJvHNGDr7CaS0h8U/BNjGZGLGoWB7HCAvZGsvxvPx0oZhV4fpFJqYMIn22kypckcTp1vkShdb4J7kG5A/QJt"
}


# VPC
resource "aws_vpc" "main" { cidr_block = "172.31.0.0/16" }


# Subnets
resource "aws_subnet" "one" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.0.0/20"
    availability_zone = "us-east-1a"

    tags {
        Name = "One"
    }
}

resource "aws_subnet" "two" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.16.0/20"
    availability_zone = "us-east-1d"

    tags {
        Name = "Two"
    }
}

resource "aws_subnet" "three" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.32.0/20"
    availability_zone = "us-east-1e"

    tags {
        Name = "Three"
    }
}

resource "aws_subnet" "four" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.48.0/20"
    availability_zone = "us-east-1c"

    tags {
        Name = "Four"
    }
}


# Bucket ACL
/*data "aws_iam_policy_document" "logging_and_alb" {

    statement {
        actions = [
            "s3:ListAllMyBuckets",
            "s3:GetBucketLocation",
        ]
        resources = [ "arn:aws:s3:::massgo" ]
        principals = [
    }

    statement {
        actions = [
            "s3:ListBucket",
        ]
        resources = [
            "arn:aws:s3:::${var.s3_bucket_name}",
        ]
        condition {
            test = "StringLike"
            variable = "s3:prefix"
            values = [
                "",
                "home/",
                "home/&{aws:username}/",
            ]
        }
    }

    statement {
        actions = [
            "s3:*",
        ]
        resources = [
            "arn:aws:s3:::${var.s3_bucket_name}/home/&{aws:username}",
            "arn:aws:s3:::${var.s3_bucket_name}/home/&{aws:username}/*",
        ]
    }

}*/

/*resource "aws_iam_policy" "logging" {
    name = "logging"
    path = "/"
    policy = "${data.aws_iam_policy_document.logging.json}"
}*/


# Buckets
resource "aws_s3_bucket" "logs" {
    bucket = "massgo-logs"
    versioning { enabled = false }
    acl = "private"
}

resource "aws_s3_bucket" "tfstate" {
    bucket = "massgo-terraform"
    versioning { enabled = true }
    acl = "private"

    logging
    {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/terraform/"
    }
}


# Zones
resource "aws_route53_zone" "root" { name = "aws.massgo.org" }


# Security groups
resource "aws_security_group" "web-prod" {
    name = "web_prod"
    description = "Allow inbound HTTP/S traffic from anywhere"

    ingress
    {
        from_port = 0
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress
    {
        from_port = 0
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags
    {
        Name = "web_prod"
    }
}

resource "aws_security_group" "ssh-gbre" {
    name = "ssh_gbre"
    description = "Allow SSH traffic from gbre.org"

    ingress
    {
        from_port = 0
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["73.234.173.33/32"]
    }

    tags
    {
        Name = "ssh_gbre"
    }
}

resource "aws_security_group" "outbound-all" {
    name = "outbound_all"
    description = "Allow all outbound traffic"

    egress
    {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags
    {
        Name = "outbound_all"
    }
}

resource "aws_security_group" "ssh-vpc" {
    name = "ssh_vpc"
    description = "Allow SSH traffic from our VPC"

    ingress
    {
        from_port = 0
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    }

    tags
    {
        Name = "ssh_gbre"
    }
}
