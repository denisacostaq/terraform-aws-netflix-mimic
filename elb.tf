# resource "aws_s3_bucket" "service-load-balancer-logs" {
#   name = "service-load-balancer-logs"
# }

resource "aws_lb" "service-http" {
  name = "service-http"
  load_balancer_type = "application"
  internal = false
  security_groups = [ aws_security_group.allow_global_http.id ]
  subnets = [for np in aws_subnet.service-public: np.id]

  tags = {
    Name = "service_http_load_balancer"
  }
}

resource "aws_lb_target_group" "service" {
  for_each = toset(var.services)
  name     = each.value
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.service.id
}

resource "aws_lb_listener" "service" {
  load_balancer_arn = aws_lb.service-http.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Page not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "home" {
  listener_arn = aws_lb_listener.service.arn
  priority     = 80

  action {
    type             = "redirect"
    redirect {
      path = "/${var.services[0]}"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_listener_rule" "service" {
  for_each = toset(var.services)
  listener_arn = aws_lb_listener.service.arn
  priority     = index(var.services, each.value) + 1

  action {
    type             = "forward"
    target_group_arn = lookup(aws_lb_target_group.service, each.value).arn
  }

  condition {
    path_pattern {
      values = ["/${each.value}*"]
    }
  }
}

resource "aws_lb_target_group_attachment" "service" {
  for_each = local.instances-spread
  target_group_arn = lookup(aws_lb_target_group.service, each.value.service).arn
  target_id        = aws_instance.worker-node[each.key].id
  port             = 80
}
