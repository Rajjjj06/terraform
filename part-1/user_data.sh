#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y git python3 python3-pip python3-venv nodejs npm

cd /home/ubuntu
git clone https://github.com/Rajjjj06/Frontend_Backend project

cd /home/ubuntu/project/backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
nohup .venv/bin/python app.py > /var/log/backend.log 2>&1 &

cd /home/ubuntu/project/frontend
npm install
BACKEND_URL=http://127.0.0.1:5000 PORT=3000 nohup npm start > /var/log/frontend.log 2>&1 &
