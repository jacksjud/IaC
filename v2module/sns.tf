resource "aws_sns_topic" "alarm" {

    name = "alarms-topic"

    delivery_policy = <<EOF
    {
    "http": {
        "defaultHealthyRetryPolicy": {
            "minDelayTarget": 20,
            "maxDelayTarget": 20,
            "numRetries": 3,
            "numMaxDelayRetries": 0,
            "numNoDelayRetries": 0,
            "numMinDelayRetries": 0,
            "backoffFunction": "linear"
        },
        "disableSubscriptionOverrides" : false,
        "defaultThrottlePolicy": {
            "maxReceivesPerSecond": 1
            }
        }
    }   
    EOF

    provisioner "local-exec" {
        command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
      
    }
}

# Should be in variables.tf with actual email in terraforms.tfvars 
variable "alarms_email" {
    default = "default@gmail.com"
}

# Should be in outputs.tf
output "sns_topic" {
    value = "${aws_sns_topic.alarm.arn}"  
}