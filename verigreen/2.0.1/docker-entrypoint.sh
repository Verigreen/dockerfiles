#!/bin/bash
# 
# # run.sh
# 
# This script bootstraps the environment for Verigreen and runs the app using Tomcat.
# 
#
# ## Assumptions
# - Verigreen collector (webapp) should be installed previously in the tomcat webapps directory.
# - `catalina.sh` should be in the current `PATH`. 
# - SSH keys to access the git remote repository must be placed in the current `$HOME/.ssh` of the current user.
# - A `$HOME/.ssh/config` file that will associate the keys with a particular domain. Example, for a repository in `ssh://my.example.com/my/repo.git`
# write a config file as such:
# 
# ```
# Host my.example.com
# User myuser
# IdentityFile ~/.ssh/my_private_key
# ```
# 
# ## Steps:
# 
# - Verify `~/.ssh` directory and its assets: `~/.ssh/known_hosts`, `~/.ssh/config`, and `~/.ssh/known_hosts`.
# - If `~/.ssh/known_hosts` is not present, then scan the remote git repo using the `remote_url` value stored in `$VG_HOME/run.yml` file.
# - Verify that a valid git local repository (in `$VG_REPO`) is present. Otherwise, clone it to `$VG_REPO` dir.
# - Verify local git repo communication to remote.
# - Start Verigreen using Tomcat (`catalina.sh run`).
#
# ## Author(s): 
# - Ricardo Quintana <https://github.com/rqc>
#

# Downloads the ssh key from a remote git repository and stores it in `~/.ssh/known_hosts`
function download_git_remote_ssh_key {
	# Grab the domain
	domain=$(echo "$1" | awk -F/ '{print $3}')

	# But it could have the username and port, so just extract the domain
	echo $domain | grep "@"

	if [ $? -eq 0 ]; then
		domain=$(echo $domain | awk -F@ '{print $2}') 
	else
		echo "No username found, continuing."
	fi

	# If it has the port, SSH needs that port to extract the fingerprint (e.g. from Stash and not the sshd server)
	echo $domain | grep ":"
	[ $? -eq 0 ] && domain_port="$domain" && port=$(echo $domain | awk -F: '{print $2}')  && domain=$(echo $domain | awk -F: '{print $1}') || echo "No port found, continuing."

	# Grab the ip address of the host that was passed
	ip_address=$(host $domain | awk -F' has address ' '{print $2}')

	# Scan the Git server and save the fingerprint to the `~/.ssh/known_hosts` file
	# This will avoid SSH to ask the user for input upon a *new* host connection.
	# **WARNING**: `ssh-keyscan` outputs the key in a non-standard format. 
	# For this reason, we need to format the output so that `JGit/JCSH` likes the format of the key in `~./ssh/known_hsots` as explained [here](http://sourceforge.net/p/jsch/bugs/63/).
	if [ -z "$domain_port" ]; then
		# No port option, no domain + port and no ip address + port will default `awk` `sub` to replace to same value.
		domain_port="$domain"
		ip_address_port="$ip_address"
	else
		# Add port option
		# Format the entry correctly
		port_option="-p $port"
		domain_port="[$domain]:$port"
		ip_address_port="[$ip_address]:$port"
	fi

	echo "Found domain $domain_port"
	echo "Found ip address $ip_address_port"

	# Grab git remote's public key and store it in `$KNOWN_HOSTS` for the `domain` + `port`
	ssh-keyscan -t ssh-rsa "$port_option" "$domain" | awk -v domain="$domain" -v domain_port="$domain_port" '{sub(domain,domain_port)}1' | tee $SSH_KNOWN_HOSTS
	if [ $? -ne 0 ]; then
		echo "ERROR: could not retrieve ssh key from $domain_port."
		exit -1
	fi
	
	echo "Retrieved ssh key for $domain_port and stored it in $KNOWN_HOSTS"
	
	# Grab git remote's public key and store it in `$KNOWN_HOSTS` for `ip_address` + `port`
	ssh-keyscan -t ssh-rsa "$port_option" "$ip_address" | awk -v ip_address="$ip_address" -v ip_address_port="$ip_address_port" '{sub(ip_address,ip_address_port)}1' | tee -a $SSH_KNOWN_HOSTS
	if [ $? -ne 0 ]; then
		echo "ERROR: could not retrieve ssh key from $ip_address_port."
		exit -1
	fi

	echo "Retrieved ssh key for $ip_address_port and stored it in $KNOWN_HOSTS"	
}

# Clones a git remote repository. Used when a local repository is not available in the `$VG_REPO` path (e.g. you may map an existing repo as a volume from host).
function clone_fresh_repo {
	echo "Checking if we can clone a fresh copy of the remote repository."
	
	if [ -z "$remote_repository_url" ]; then
		echo "ERROR: could not find a key/value for remote_url in $VG_HOME/run.yml file."
		exit -1
	fi	
	
	git clone "$remote_repository_url" "$clean_repo_path"

	if [ $? -ne 0 ]; then
		echo "ERROR: could not perform git clone of $remote_repository_url. Verify that your remote endpoint is correct and that the ssh keys and configurations are correct."
		exit -1
	fi
	
	echo "SUCCESS: cloned $remote_repository_url to $clean_repo_path."	
}

# Extract configuration values needed before running Verigreen.
function extract_config_values {
	
	# Extract the local repository path from `$VG_HOME/config.properties` file. Remove `/.git` from the path if it has it.
	repo_from_config_properties=$(cat $VG_HOME/config.properties | grep "git.repositoryLocation" | awk -F= '{print $2}' | awk -F/.git '{print $1}')

	# Compare the local repo path from `config.properties` with the one in `$VG_REPO`
	if [ "$repo_from_config_properties" != "$VG_REPO" ]; then
		echo "ERROR: please verify that the values for the path to your local git repo are consistent in your $VG_HOME/config.properties and VG_REPO environment variable."
		echo "From $VG_HOME/config.properties = $repo_from_config_properties"
		echo "From VG_REPO = $VG_REPO"
		exit -1
	fi


	remote_repository_url="$(cat $VG_HOME/run.yml | grep "remote_url" | awk -F': ' '{print $2}' | awk '{gsub(/\"/,""); print}' )"


	# Check that we were able to extract the `remote_url` key/value pair.
	if [ -z "$remote_repository_url" ]; then
		echo "ERROR: the remote_url key is either missing or its value is invalid."
		exit -1
	fi		

	# Check if `known_hosts` file is there. If not, download the key from git remote.
	if [ ! -e "$SSH_KNOWN_HOSTS" ]; then
		echo "WARNING: $SSH_KNOWN_HOSTS was not found. Attempting download..."
		download_git_remote_ssh_key "$remote_repository_url"
	fi

	# Ensure that `~/.ssh/known_hosts` has the correct permissions.
	chmod 600 $SSH_KNOWN_HOSTS

	# Remove `/.git` if present so that we can cleanly clone to the correct path.
	clean_repo_path=$(echo $VG_REPO | awk -F/.git '{print $1}')

	# If the local repository is not present (e.g. user didn't map it as a volume), then clone it if possible.
	# **TODO**: perform a more robust verification for existance of local git repository.
	if [ ! -d "$VG_REPO/.git" ]; then
		echo "$VG_REPO/.git does not exist."
		clone_fresh_repo
	else
		echo "Found existing local git repository at $VG_REPO. No clone necessary."
	fi
}


# Verify that we can connect to the git remote repository.
function verify_remote_repo_connection {
	# Save where we are right now.
	previous_cwd="$PWD"

	# Change to the local git repo directory to perform a check.
	cd "$clean_repo_path"; git ls-remote > /dev/null
	if [ $? -ne 0 ]; then
		echo "ERROR: could not perform a git ls-remote on the $clean_repo_path. Verify that you have added the git remote's SSH key to $SSH_DIR/known_hosts file."
		exit -1
	fi

	echo "SUCCESS: local git repository at $clean_repo_path was able to connect to remote at $remote_repository_url"

	# Check was successful, go back to previous directory.
	cd "$previous_cwd"

	echo "SUCCESS: container environment and setup was successful."	
}

# Verify that all required assets (files) are in the right directories.
function verify_required_assets {
	# Verify that there is an `~/.ssh` dir in the container. This is required.
	if [ ! -d "$SSH_DIR" ]; then
		echo "ERROR: please map a volume from host to $SSH_DIR in your container."
		exit -1
	fi

	# Change permissions to host's directory that was mapped as a volume to the container.
	chmod 700 "$SSH_DIR"

	# Verify that we have a `~/.ssh/config` file. This is the preferred method for ensuring ssh access to git remote repo.
	if [ -e "$SSH_CONFIG_FILE" ]; then
		chown root:root $SSH_CONFIG_FILE
		chmod 600 $SSH_CONFIG_FILE
	else
		echo "ERROR: make sure that your config file is added to the volume mapped to $SSH_DIR"
		exit -1
	fi


	# Verify that the `$VG_HOME/config.properties` file is present.
	if [ ! -e "$VG_HOME/config.properties" ]; then
		echo "ERROR: could not find $VG_HOME/config.properties. Make sure to map it to a volume from your host."
		exit -1
	fi

	# Verify that the `$VG_HOME/run.yml` file is present.
	if [ ! -e "$VG_HOME/run.yml" ]; then
		echo "ERROR: could not find $VG_HOME/run.yml. Make sure to map it from a volume from your host."
		exit -1
	fi
}


# Verifies all environment variables and configuration needed to run this script and Verigreen.
function verify_required_environment {

	if [ -z "$ROOT_SSH_DIR" ]; then
		echo "ERROR: ROOT_SSH_DIR environment variable is not set."
		exit -1
	fi

	if [ -z "$VG_HOME" ]; then
		echo "ERROR: VG_HOME environment variable is not set."
		exit -1
	fi

	if [ -z "$VG_REPO" ]; then
		echo "ERROR: VG_REPO environment variable is not set."
		exit -1
	fi
}

# Verify that the environment is suitable for running this script and Verigreen.
verify_required_environment

# Point to container's ssh files that will be used to perform git commands on remote repo.
# The `$ROOT_SSH_DIR` should be set *a priori*.
SSH_DIR="$ROOT_SSH_DIR"
SSH_CONFIG_FILE="$SSH_DIR/config"
SSH_KNOWN_HOSTS="$SSH_DIR/known_hosts"

# Verify that all required assets are present, if not, then fail.
verify_required_assets

# Extract required configuration from the assets. If not available, the  fail.
extract_config_values

# At this point, we should have a repo available with all the necessary ssh configuration necessary for git to work correctly.
verify_remote_repo_connection

echo "Launching Verigreen"

# Run Tomcat using the `catalina.sh` script that comes bundled with it. 
# It should be in the `PATH` as per the base tomcat image.
catalina.sh run