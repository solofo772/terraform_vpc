# Instance publique dans la nouvelle zone eu-west-3a
resource "aws_instance" "private-instance" {
  ami           = "ami-0a3598a00eff32f66"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-subnet-1.id
  key_name = "ssh"
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  tags = {
    Name = "private-instance"
  }
  # User Data pour installer Nginx
#  user_data = file("nginx.sh")
}

resource "aws_instance" "public-instance" {
  ami           = "ami-0a3598a00eff32f66"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet-1.id
  associate_public_ip_address = true
  key_name = "ssh"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  tags = {
    Name = "public-instance"
  }
}

# Instance publique dans la nouvelle zone eu-west-3b
resource "aws_instance" "private-instance-b" {
  ami           = "ami-0a3598a00eff32f66"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-subnet-2.id  
  key_name      = "ssh"
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  tags = {
    Name = "private-instance-b"
  }
#    user_data = file("apache.sh")
}

resource "aws_instance" "public-instance-b" {
  ami           = "ami-0a3598a00eff32f66"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet-2.id 
  associate_public_ip_address = true
  key_name      = "ssh"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  tags = {
    Name = "public-instance-b"
  }
}