resource "aws_lb" "netflix-http" {
  name = "netflix-http"
  load_balancer_type = "application"
  internal = false
  security_groups = [ aws_security_group.allow_global_http.id ]
  subnets = [ aws_subnet.public-1a.id, aws_subnet.public-1b.id ]

  tags = {
    Name = "netflix_http_load_balancer"
  }
}

resource "aws_lb_target_group" "netflix" {
  name     = "netflix"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.netflix.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.netflix-http.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.netflix.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.netflix.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group_attachment" "netflix_home" {
  target_group_arn = aws_lb_target_group.netflix.arn
  target_id        = aws_instance.home-node["eu-central-1c_home"].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "netflix_stream" {
  target_group_arn = aws_lb_target_group.netflix.arn
  target_id        = aws_instance.stream-node["eu-central-1c_home"].id
  port             = 80
}