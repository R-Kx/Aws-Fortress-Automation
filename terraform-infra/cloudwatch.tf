resource "aws_sns_topic" "cpu_alert" {
    name = "${var.project_name}-cpu-alert"
}

resource "aws_sns_topic_subscription" "mail_sub" {
    topic_arn = aws_sns_topic.cpu_alert.arn
    protocol  = "email"
    endpoint  = var.my_mail
}

resource "aws_cloudwatch_log_group" "api_logs" {
    name              = "api-logs"
    retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
    alarm_name          = "high-cpu-utilization"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "300"
    statistic           = "Average"
    threshold           = "70"

    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.flask_asg.name
    }

    alarm_actions = [aws_sns_topic.cpu_alert.arn]
    ok_actions    = [aws_sns_topic.cpu_alert.arn]
}