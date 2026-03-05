#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "flask_alb" {
    name               = "flask-alb"
    subnets            = aws_subnet.public[*].id
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb_sg.id]
    drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "flask_tg_group" {
    name        = "${var.project_name}-alb-tg"
    port        = 5000
    protocol    = "HTTP"
    vpc_id      = aws_vpc.flask_vpc.id
    target_type = "instance"

    health_check {
        healthy_threshold   = "3"
        interval            = "15"
        protocol            = "HTTP"
        matcher             = "200-299"
        timeout             = "10"
        path                = "/healthcheck"
        port                = "5000"
        unhealthy_threshold = "2"
    }
}

resource "aws_lb_listener" "https_forward" {
    load_balancer_arn  = aws_lb.flask_alb.arn
    port               = 80
    protocol           = "HTTP" #tfsec:ignore:aws-elb-http-not-used

    default_action {
        type     = "forward"
        target_group_arn = aws_lb_target_group.flask_tg_group.arn
    }
}