Verigreen on Docker
===================

## Usage

```
docker run -it -v /path/to/ssh/assets:/root/.ssh -v /path/to/verigreen/config:/var/vg/config -p 8085:8080 verigreen/vg-collector
```

##  Configuration
Mapping the `/root/.ssh` and `/var/vg/config` volumes **is required**. The minimal contents of those volumes are:

- `/var/vg/config` should have a `config.properties` file that `verigreen` will use as a configuration file (example [here](https://github.com/Verigreen/verigreen/blob/master/verigreen-collector-webapp/resources/config.properties)) and a `run.yml` file that is used during container setup that should look something like this:

```
# /var/vg/config/run.yml
repository:
  remote_url: "ssh://<domain>:<port>/path/to/repo.git"
```

- `/root/.ssh` should have the following files:

  - `/root/.ssh/id_rsa` which is the private key file for the *remote* repository you are trying to protect.

  - `/root/.ssh/id_rsa.pub` which is the public key for the *remote* repository you are trying to protect. 

  - `/root/.ssh/config` file that configures `ssh` to use the above-mentioned keys when accessing the right domain. For example for domain `my.example.com` and user `myuser` you could have a `config` file that looks like this:

  - `/root/.ssh/known_hosts` file **is optional**. If it specified, it should contain the public key for the git server (e.g. Atlassian Stash) which hosts the git remote repository. If it is not specified, this container provides a `run.sh` script that will attempt to retrieve the key by using the value for `remote_url` in the `/var/vg/config/run.yml`. 

```
# /root/.ssh/config
Host my.example.com
User myuser
IdentityFile ~/.ssh/id_rsa
```
