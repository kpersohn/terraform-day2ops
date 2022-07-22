resource "aws_launch_template" "refresh" {
  name                   = local.env_name
  image_id               = data.aws_ami.amzn2.id
  instance_type          = "t3.nano"
  key_name               = local.key_name
  user_data              = filebase64("${path.module}/user-data.sh")
  vpc_security_group_ids = [aws_security_group.instance.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.env_name}-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "refresh" {
  name                      = local.env_name
  desired_capacity          = local.num_azs
  health_check_grace_period = 60
  health_check_type         = "ELB"
  max_size                  = local.num_azs
  min_size                  = local.num_azs
  target_group_arns         = [aws_lb_target_group.http.arn]
  vpc_zone_identifier       = aws_subnet.public.*.id
  wait_for_elb_capacity     = local.num_azs

  launch_template {
    id      = aws_launch_template.refresh.id
    version = aws_launch_template.refresh.latest_version
  }


  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 66
    }
    triggers = ["tag"]
  }
}

resource "null_resource" "wait_for_refresh" {
  triggers = {
    id      = aws_autoscaling_group.refresh.launch_template[0].id
    version = aws_autoscaling_group.refresh.launch_template[0].version
    tag     = join(",", [for key, value in aws_autoscaling_group.refresh.tag : "${key}=${value}"])
  }
  
  provisioner "local-exec" {
    command = "python3 checkout.py"
    
    environment = {
      ASG_NAME = aws_autoscaling_group.refresh.name
    }
  }
}

# resource "aws_launch_configuration" "bluegreen" {
#   name_prefix     = "bluegreen-"
#   image_id        = data.aws_ami.amzn2.id
#   instance_type   = "t3.nano"
#   key_name        = local.key_name
#   security_groups = [aws_security_group.instance.id]
#   user_data       = filebase64("${path.module}/user-data.sh")

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "bluegreen" {
#   name                      = aws_launch_configuration.bluegreen.name
#   desired_capacity          = local.num_azs
#   health_check_grace_period = 60
#   health_check_type         = "ELB"
#   launch_configuration      = aws_launch_configuration.bluegreen.name
#   min_size                  = local.num_azs
#   max_size                  = local.num_azs
#   target_group_arns         = [aws_lb_target_group.http.arn]
#   vpc_zone_identifier       = aws_subnet.public.*.id
#   wait_for_elb_capacity     = local.num_azs

#   lifecycle {
#     create_before_destroy = true
#   }
# }
