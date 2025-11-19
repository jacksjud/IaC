#####################################################################
# Configuration and Security Groups

# Get default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Get subnets in the default VPC
data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }

  filter {
    name   = "tag:Environment"
    values = ["boot_test"]
  }
}

#####################################################################
# Security group for instances
resource "aws_security_group" "instances" {
  name        = "${var.app_name}-${var.env_name}-instance-security-group"
  description = "Allow ELB access"
  vpc_id      = data.aws_vpc.default_vpc.id
}

# Allow HTTP (app traffic) from ELB only
resource "aws_security_group_rule" "allow_http_inbound_from_elb" {
    type              = "ingress"
    security_group_id = aws_security_group.instances.id
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"

    # Only allow traffic coming from the ELB's security group
    source_security_group_id = aws_security_group.elb.id
}

# Allow SSH from my IP (debugging only)
# resource "aws_security_group_rule" "allow_ssh_inbound" {
#     type = "ingress"
#     security_group_id = aws_security_group.instances.id
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
# }

# Allow all outbound (so. the instance can talk to the internet)
resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.instances.id
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
}

#####################################################################
# Security group for Classic Load Balancer
resource "aws_security_group" "elb" {
  name        = "${var.app_name}-${var.env_name}-classic-elb-sg"
  description = "Security group for Classic ELB"
  vpc_id      = data.aws_vpc.default_vpc.id
}

# Allow HTTP from anywhere
resource "aws_security_group_rule" "allow_elb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.elb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allows Load Balancer to accept requests from port 443 given any IP
resource "aws_security_group_rule" "allow_elb_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.elb.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow outbound to anywhere
resource "aws_security_group_rule" "allow_elb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.elb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
