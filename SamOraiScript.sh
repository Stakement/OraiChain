#!/bin/bash
# env	 : Ubuntu 20.04.1 LTS (Focal Fossa)
# name	 : SamOraiScript.sh
# authors: Stakement.io
# date	 : 2021.02.14-2021.02.16
# version: 0.1

# make excutubel: chmod +x ./scripts/SamOraiScript.sh

function install_docker()
{
	echo "$1.Install docker ...)"
	
	# Update the apt package index and install packages to allow apt to use a repository over HTTPS:
	sudo apt-get update

	sudo apt-get install \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common
	
	# Schedule tasks 'crontab'	
	sudo apt-get install jq
	
	# Add Docker’s official GPG key:
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	
	# Use the following command to set up the stable repository
	sudo add-apt-repository \
		"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) \
		stable"
	
	# Install the latest version of Docker Engine and containerd
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io

	echo -e "Install docker-compose ..."
	sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" \
		-o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose

	pause
}

function install_and_run_orai()
{
	echo -e "$1.Install_and_run_orai ..."
	curl -OL https://raw.githubusercontent.com/oraichain/oraichain-static-files/master/setup.sh && chmod +x ./setup.sh && ./setup.sh
	sudo apt install jq
	sleep 5
	
	# Edit orai.env
	sudo nano orai.env
	
	# Start validator node
	docker-compose pull && docker-compose up -d --force-recreate

	# Fill necessary information (mnemonic 24-word phrase and passphrase)
	docker-compose exec orai bash -c 'wget -O /usr/bin/fn https://raw.githubusercontent.com/oraichain/oraichain-static-files/master/fn.sh && chmod +x /usr/bin/fn' && docker-compose exec orai fn init
	
	docker-compose ps

	# Run node as a background process
	docker-compose restart orai && docker-compose exec -d orai fn start --log_level info --seeds "db17ded030e8e7589797514f7e1b343b98357612@178.128.61.252:26656,1e65e100baa0b7381df47606c12c5d0bdb99cdb2@157.230.22.169:26656,a1440e003576132b5e96e7f898568114d47eb2df@165.232.118.44:26656"
	
	pause
}

function fully_synced()
{
	echo -e "$1.Check if node has fully synced ..."
	docker exec orai_node oraid status &> /tmp/status.json && cat /tmp/status.json | jq '{catching_up: .SyncInfo.catching_up, latest_block_height: .SyncInfo.latest_block_height, voting_power: .ValidatorInfo.VotingPower}'

	pause
}


function unsinstall_container_and_orainode()
{
	echo -e "$1.Unsinstall Container and Orai node!"
	# Stop Orai node
	docker-compose stop orai
	
	# Shut down container
	docker kill orai_node
	docker container prune
	docker-compose down

	# Delete all Orai files
	rm -rf .oraid/ .oraicli/ .oraifiles/
	ls -la
	pause
}

function pause() 
{
	read -s -n 1 -p "Press any key to continue."
	echo ""
}

# Define screen colors:
RED='\E[0;31m'; CYAN='\E[1;36m'; GREEN='\E[0;32m'; BLUE='\E[1;34m'; NC='\E[0m';

# Main
# Read laste choice
if [[ -f $"/tmp/choice" ]]; then
	choice=$(cat /tmp/choice)
fi

# Starting loop
for (( ; ; ));  do
	clear; reset
	echo -e "${GREEN}SamOraiScript (c) v0.1 2021 - Your laste choice was ($choice)${GREEN}"
	echo -e " 1. Install Docker"
	echo -e " 2. Install and run Orai"
	echo -e " 3. Check if node has fully synced"
	echo -e "    -----"
	echo -e " 8. Unsinstall container and Orai node"
	echo -e "    -----"
	echo -e " 0. Exit${BLUE}"
	read -p "Please select an action : " choice
	echo -e "${NC}"
		
	case $choice in
		1) install_docker $choice;;
		2) install_and_run_orai $choice;;
		3) fully_synced  $choice;;
		8) unsinstall_container_and_orainode $choice;;
		0) exit;;
		*) echo "Sorry, I don't understand, you have not choice!";;
	esac
	echo $choice > /tmp/choice
done

#end script
