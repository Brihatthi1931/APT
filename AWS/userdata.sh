#!/bin/bash
yum update -y
yum install -y python3 git
git clone https://github.com/<your-username>/apt-assignment.git /opt/app
pip3 install flask
nohup python3 /opt/app/app/main.py &
