#####################################################################
# Used to query for the most recent official amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


#####################################################################
# Amazon Instance for EC2
# resource "aws_instance" "web" {
#     ami = var.ami == "" ? data.aws_ami.amazon_linux_2.id : var.ami
#     instance_type = var.instance_type
#     tags = {
#         Name = "${var.app_name}-${var.env_name}-ec2-instance"
#     }

#     security_groups = [ aws_security_group.instances.name ]


#     # To more easily SSH or EC2 Connect
#     associate_public_ip_address = true

#     # TEMP
#     user_data = ""
# }

# AWS instances, still using free tier

resource "aws_instance" "instance_1" {
    ami = var.ami == "" ? data.aws_ami.amazon_linux_2.id : var.ami
    instance_type = var.instance_type
    tags = {
        Name = "${var.app_name}-${var.env_name}-ec2-instance_1"
    }

    security_groups = [ aws_security_group.instances.name ]


    # To more easily SSH or EC2 Connect
    associate_public_ip_address = true

    # Updated user_data because the Amazon Linux 2 uses bash that runs user_data once
    # so if it fails for any reason (like not having Python), no service is listening
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y python3
                cd /home/ec2-user
                echo "Hello, World 1" > index.html
                nohup python3 -m http.server 8080 &
                EOF


}

resource "aws_instance" "instance_2" {
    ami = var.ami == "" ? data.aws_ami.amazon_linux_2.id : var.ami
    instance_type = var.instance_type
    tags = {
        Name = "${var.app_name}-${var.env_name}-ec2-instance_2"
    }

    security_groups = [ aws_security_group.instances.name ]


    # To more easily SSH or EC2 Connect
    associate_public_ip_address = true

    # Updated user_data because the Amazon Linux 2 uses bash that runs user_data once
    # so if it fails for any reason (like not having Python), no service is listening
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y python3
                cd /home/ec2-user
                echo "Hello, World 2" > index.html
                nohup python3 -m http.server 8080 &
                EOF
}

#####################################################################
# Classic Load Balancer (ELB)

resource "aws_elb" "classic_lb" {
  name               = "${var.app_name}-${var.env_name}-celb"
  availability_zones = [ "us-west-2a", "us-west-2b", "us-west-2c" ]
  subnets            = data.aws_subnets.default_subnet.ids
  security_groups    = [aws_security_group.elb.id]
  cross_zone_load_balancing = true
  idle_timeout                = 60
  connection_draining         = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 8080
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate.site_cert.arn
  }

  health_check {
    target              = "HTTP:8080/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [
    aws_instance.instance_1.id,
    aws_instance.instance_2.id
  ]

  tags = {
    Name = "${var.app_name}-${var.env_name}-classic-web-elb"
  }
}
