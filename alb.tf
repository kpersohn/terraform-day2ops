resource "aws_lb" "refresh" {
  name               = local.env_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public.*.id
}

resource "aws_lb_listener" "refresh" {
  load_balancer_arn = aws_lb.refresh.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group" "http" {
  name                 = "${local.env_name}-http"
  deregistration_delay = 10
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    interval            = 10
    matcher             = "200"
    path                = "/"
    unhealthy_threshold = 2
  }
}
