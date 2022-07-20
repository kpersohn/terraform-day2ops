
# # what about stateful workloads 
# * ex, cluster backends
# * need to do research to figure out how to wait for healthcheck with null resource
# * 



# <pre><font color="#C01C28">│</font> <font color="#C01C28"><b>Error: </b></font><b>Invalid expression</b>
# <font color="#C01C28">│</font> 
# <font color="#C01C28">│</font>   on ec2.tf line 33, in resource &quot;aws_instance&quot; &quot;stateful&quot;:
# <font color="#C01C28">│</font>   33:     <u style="text-decoration-style:single">count.index != 0 ? aws_instance.stateful[0] : aws_instance.stateful[count.index - 1]</u>
# <font color="#C01C28">│</font> 
# <font color="#C01C28">│</font> A single static variable reference is required: only attribute access and indexing with constant keys. No
# <font color="#C01C28">│</font> calculations, function calls, template expressions, etc are allowed here.
# </pre>

# what you can't do
# - cyclic depends explicit, can't do conditionals
# - cyclic dpeneds implicit with user data or something, graph only analyzies group of resources not individual
# - dynamic blocks, for_each, etc
# - 

# can do parallelism = 1, with drawback of all resources


# another variation is to use null_resource w/ remote provisioner

# issue: destroys are all prcoeeding before create, neeed to try lifecycle hooks and/or moving provisionrer to null_resource see if that helps


# https://discuss.hashicorp.com/t/is-there-a-way-to-daisy-chain-depends-on-for-resources-created-using-count-or-for-each/8467/5

# module "stateful_ec2_0" {
#   source                 = "./stateful_ec2"
#   name                   = local.env_name
#   ami                    = data.aws_ami.amzn2.id
#   index                  = 0
#   key_name               = local.key_name
#   subnet_id              = aws_subnet.public[0].id
#   vpc_security_group_ids = [aws_security_group.instance.id]
# }

# module "stateful_ec2_1" {
#   source                 = "./stateful_ec2"
#   name                   = local.env_name
#   ami                    = data.aws_ami.amzn2.id
#   index                  = 1
#   key_name               = local.key_name
#   subnet_id              = aws_subnet.public[1].id
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   depends_on = [module.stateful_ec2_0]
# }

# module "stateful_ec2_2" {
#   source                 = "./stateful_ec2"
#   name                   = local.env_name
#   ami                    = data.aws_ami.amzn2.id
#   index                  = 2
#   key_name               = local.key_name
#   subnet_id              = aws_subnet.public[2].id
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   depends_on = [module.stateful_ec2_1]
# }

# resource "aws_instance" "stateful0" {
#   ami                    = data.aws_ami.amzn2.id
#   instance_type          = "t3.nano"
#   key_name               = local.key_name
#   subnet_id              = aws_subnet.public[0].id
#   user_data              = filebase64("${path.module}/user-data.sh")
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   tags = {
#     Name = "${local.env_name}-stateful-ec2-0}"
#   }

#   maintenance_options {
#     auto_recovery = "default"
#   }
# }

# resource "null_resource" "wait0" {
#   triggers = {
#     id = aws_instance.stateful0.id
#   }

#   connection {
#     type        = "ssh"
#     user        = "ec2-user"
#     private_key = file("~/.ssh/id_rsa")
#     host        = aws_instance.stateful0.public_ip
#   }
  
#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Waiting for httpd to start...'",
#       "until $(curl --output /dev/null --silent --head --fail localhost); do printf '.'; sleep 5; done"
#     ]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
  
#   depends_on = [aws_instance.stateful0]
# }

# resource "aws_ebs_volume" "state0" {
#   availability_zone = aws_subnet.public[0].availability_zone
#   size              = 10

#   tags = {
#     Name = "${local.env_name}-vol-0}"
#   }
# }

# resource "aws_volume_attachment" "state0" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.state0.id
#   instance_id = aws_instance.stateful0.id
# }

# resource "aws_instance" "stateful1" {
#   ami                    = data.aws_ami.amzn2.id
#   instance_type          = "t3.nano"
#   key_name               = local.key_name
#   subnet_id              = aws_subnet.public[1].id
#   user_data              = filebase64("${path.module}/user-data.sh")
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   tags = {
#     Name = "${local.env_name}-stateful-ec2-1}"
#   }

#   maintenance_options {
#     auto_recovery = "default"
#   }

#   depends_on = [null_resource.wait0, aws_volume_attachment.state0]
# }

# resource "aws_ebs_volume" "state1" {
#   availability_zone = aws_subnet.public[1].availability_zone
#   size              = 10

#   tags = {
#     Name = "${local.env_name}-vol-1}"
#   }
# }

# resource "aws_volume_attachment" "state1" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.state1.id
#   instance_id = aws_instance.stateful1.id
# }

# resource "null_resource" "wait1" {
#   triggers = {
#     id = aws_instance.stateful1.id
#   }
  
#   connection {
#     type        = "ssh"
#     user        = "ec2-user"
#     private_key = file("~/.ssh/id_rsa")
#     host        = aws_instance.stateful1.public_ip
#   }
  
#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Waiting for httpd to start...'",
#       "until $(curl --output /dev/null --silent --head --fail localhost); do printf '.'; sleep 5; done"
#     ]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
  
#   depends_on = [aws_instance.stateful1]
# }
