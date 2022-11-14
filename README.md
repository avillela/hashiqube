# HashiQube with Traefik and Nomad/Vault Integration

## About

This is a fork of the updated [`servian/hashiqube`](https://github.com/servian/hashiqube) repo which uses the [Vagrant Docker Provider](https://developer.hashicorp.com/vagrant/docs/providers/docker), which enables users to run HashiQube on Mac M1 processors.

It includes the following modifications:

1. Update [traefik.nomad](hashicorp/nomad/jobs/traefik.nomad) to support gRPC endpoints on port `7233`.
2. Configure Nomad to allow it to pull Docker images from private GitHub repos given a GitHub personal access token (PAT). (See item #2 in the [Quickstart](#quickstart)).
4. Configure Nomad/Vault integration so that you can use Nomad to pull secrets from Vault. See [`hashicorp/nomad.sh`](hashicorp/nomad.sh) and [`hashicorp/vault.sh`](hashicorp/vault.sh)
5. Add an [OpenTelemetry Collector job](hashicorp/nomad/jobs/otel-collector.nomad).
6. Add a sample [2048-game job](hashicorp/nomad/jobs/2048-game.nomad).

## !! WARNING !!

For backward compatibility, the version of HashiQube used in my [HashiQube series of blog posts on Medium](https://medium.com/@adri-v/list/hashiqube-bfdcb9c84e10) can be found on the [main](https://github.com/avillela/hashiqube/blob/main/README.md) branch.

## Pre-requisites

* [Docker](https://www.docker.com) (version 20.10.17 at the time of this writing)
* [Vagrant](https://www.vagrantup.com/) (version 2.3.1 at the time of this writing)
* [A GitHub Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## Quickstart

To get started:

1. Clone the repo

    ```bash
    git clone git@github.com:avillela/hashiqube.git
    git checkout m1_support
    ```

2. Configure the Docker plugin

    > **Note:** If you wish to skip this configuration, simply comment out [lines 46–52](hashicorp/nomad.sh#L46-L52) and lines [74–88](hashicorp/nomad.sh#L74-L88) in [`nomad.sh`](hashicorp/nomad.sh).

    The [`nomad.sh`](hashicorp/nomad.sh) file has some additional configuration which enables you to pull Docker images from a private GitHub repo. This is enabled in [lines 46–52](hashicorp/nomad.sh#L46-L52) in the docker stanza, telling it to pull your Docker repo secrets from `/etc/docker/docker.cfg`, which is configured in [lines 74–88](hashicorp/nomad.sh#L74-L88).

    [Line 79](hashicorp/nomad.sh#L79) expects a GitHub auth token, which is made up of your GitHub username and [GitHub PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). It pulls that information from a file called `secret.sh`, located at `vagrant/hashicorp/nomad` on the guest machine (mapped to `hashiqube/hashicorp/nomad` on the host machine).

    For your convenience, you can create `secret.sh` on your host machine like this (assuming you're starting from the hashiqube repo root directory):

    ```bash
    cat hashicorp/nomad/secret.sh
    echo "export GH_USER=<your_gh_username>" > hashicorp/nomad/secret.sh
    echo "export GH_TOKEN=<your_gh_pat>" >> hashicorp/nomad/secret.sh
    ```

    Be sure to replace `<your_gh_username>` with your own GitHub username and `<your_gh_pat>` with your own GitHub PAT.

4. Start Vagrant

    **NOTE:** If you use the `DOCKER_DEFAULT_PLATFORM` flag, make sure that you unset it first, otherwise you will run into problems.

    ```bash
    cd hashiqube # if you aren't already there
    vagrant up --provision-with basetools,docker,vault,consul,nomad --provider docker
    ```

    Now wait patiently for Vagrant to provision and configure your Docker image.

    Once everything is up and running (this will take several minutes, by the way), you'll see this in the tail-end of the startup sequence, to indicate that you are good to go:

    ![image info](images/hashiqube-startup-squence.png)

5. Access the Hashi tools

    The following tools are now accessible from your host machine

    * Vault: http://localhost:8200 (Get the login token by logging into the guest machine using `vagrant ssh` and running `cat /etc/vault/init.file | grep Root`)
    * Nomad: http://localhost:4646
    * Consul: http://localhost:8500
    * Traefik: http://traefik.localhost

    If you'd like to SSH into HashiQube, you can do so by running the following from a terminal window on your host machine.

    ```bash
    vagrant ssh
    ```

6. Install the Nomad and Vault CLIs on your host machine

    If you’re using a Mac, you can install the Vault and Nomad CLIs via Homebrew like this:

    ```bash
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
    brew install hashicorp/tap/nomad
    ```

    If you’re not using a Mac, you can find your OS-specific instructions for Vault [here](https://medium.com/r/?url=https%3A%2F%2Fwww.vaultproject.io%2Fdownloads) and for Nomad [here](https://medium.com/r/?url=https%3A%2F%2Fwww.nomadproject.io%2Fdownloads). Note that these are binary installs, and they also contain the CLIs.

## Gotchas

### Exposing gRPC port 7233

I exposed gRPC port `7233` in Trafik. In order for programs on the host machine to access services on port `7233` on Vagrant, we need to expose it in the `Vagrantfile` like this:

```
config.vm.network "forwarded_port", guest: 7233, host: 7233
```

### DNS Resolution with *.localhost

If you're using a Mac and are running into issues getting your machine to resolve `*.localhost`, you need to manually add the following entries to `/etc/hosts`:

```bash
# For HashiQube
127.0.0.1   traefik.localhost
127.0.0.1   2048-game.localhost
127.0.0.1   otel-collector-http.localhost
127.0.0.1   otel-collector-grpc.localhost
```

Why do we use `127.0.0.1`? Because the Docker image is available to the host machine via `localhost`. Which means that to use `localhost` subdomains (e.g. `traefik.localhost`), you need to associate the `localhost` address (i.e. `127.0.0.1`) with them.

>**NOTE**: You'll have to keep manually adding entries to `/etc/hosts` each time you need a specific `*.localhost` entry. For example, if I need `foo.localhost` to resolve, I would add this line to the end of `/etc/hosts`: `127.0.0.1  foo.localhost`