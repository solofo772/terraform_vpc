#!/bin/bash
sudo yum update
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
