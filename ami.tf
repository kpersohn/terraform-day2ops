data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-*-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "creation-date"
    # Toggle different values to simulate upgrades and trigger refresh
    #values = ["2022-06-14T*"]
    values = ["2022-04-28T*"]
  }
}
