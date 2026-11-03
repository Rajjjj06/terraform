#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y git nodejs npm

cd /home/ubuntu
git clone https://github.com/Rajjjj06/frontend-aws.git frontend

cd /home/ubuntu/frontend
npm install
BACKEND_URL="http://${backend_public_ip}:${backend_port}" PORT=3000 nohup npm start > /var/log/frontend.log 2>&1 &