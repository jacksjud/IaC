output "instance_1_ip_addr" {
    value = aws_instance.instance_1.public_ip
}

output "instance_2_ip_addr" {
    value = aws_instance.instance_2.public_ip
}

output "db_instance_addr" {
    value = aws_db_instance.db_instance.address
}

output "elb_dns_name" {
    value =  aws_elb.classic_lb.dns_name
}