
# Our two initial instances are no longer being used, so we comment
# these outputs out, and replace it with the instance that is being used, web.
output "instance_1_ip_addr" {
    value = aws_instance.instance_1.public_ip
}

output "instance_2_ip_addr" {
    value = aws_instance.instance_2.public_ip
}

# Not actively using db, so comment out for now
# output "db_instance_addr" {
#     value = aws_db_instance.db_instance.address
# }

# output "web_instance_ip_addr" {
#     value = aws_instance.web.public_ip
# }

output "elb_dns_name" {
    value =  aws_elb.classic_lb.dns_name
}