Verigreen on Docker
===================

## Usage

To run a **Verigreen Collector** container issue the following command from the command line:

```
docker run -it -v /path/to/ssh/assets:/root/.ssh -v /path/to/verigreen/config:/var/vg/config -p 8085:8080 verigreen/vg-collector
```

Please note that the `-it` will run the container with an interactive shell, if you wish to run it as a daemon, replace the `-it` with `-d`.

Once the collector is up, you may access the collector web UI from your host at `localhost:8085`.

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

  - `/root/.ssh/known_hosts` file **is optional**. When specified, it should contain the public key for the git server (e.g. Atlassian Stash) which hosts the git remote repository. When not specified, this container provides a `run.sh` script that will attempt to retrieve the key by using the value for `remote_url` in the `/var/vg/config/run.yml`. 

```
# /root/.ssh/config
Host my.example.com
User myuser
IdentityFile ~/.ssh/id_rsa
```

## Source Code

The Verigreen [source code](https://github.com/Verigreen/verigreen) is available on Github.

## Documentation

For more information on Verigreen, please visit its [official documentation](https://github.com/Verigreen/verigreen-docs).

## License
This project is released under Apache v2.0 license
http://www.apache.org/licenses/LICENSE-2.0.html