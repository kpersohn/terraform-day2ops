variable "name" {}
variable "ami" {}
variable "index" {}
variable "key_name" {}
variable "subnet_id" {}
variable "vpc_security_group_ids" {}

data aws_subnet "current" {
  id = var.subnet_id
}

resource "aws_instance" "stateful" {
  ami                    = var.ami
  instance_type          = "t3.nano"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  user_data              = filebase64("${path.module}/user-data.sh")
  vpc_security_group_ids = var.vpc_security_group_ids

  tags = {
    Name = "${var.name}-stateful-ec2-${var.index}"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  maintenance_options {
    auto_recovery = "default"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for httpd to start...'",
      "until $(curl --output /dev/null --silent --head --fail localhost); do printf '.'; sleep 5; done"
    ]
  }
}

resource "aws_ebs_volume" "state" {
  availability_zone = data.aws_subnet.current.availability_zone
  size              = 10

  tags = {
    Name = "${var.name}-vol-${var.index}"
  }
}

resource "aws_volume_attachment" "state" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.state.id
  instance_id = aws_instance.stateful.id
}
