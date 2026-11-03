#!/bin/bash
set -euxo pipefail
apt-get update -y
apt-get install -y git python3 python3-pip python3-venv 

cd /home/ubuntu
git clone https://github.com/Rajjjj06/backend-aws.git backend

cd /home/ubuntu/backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
nohup .venv/bin/python app.py > /var/log/backend.log 2>&1 &