# HashiQube with Traefik and Nomad/Vault Integration

This is a fork of the [`servian/hashiqube`](https://github.com/servian/hashiqube) repo.

I have made the following modifications:

1. I am only running Vault, Consul, and Nomad
2. I have replaced the [Fabio load balancer](https://fabiolb.net) with the [Traefik load balancer](traefik.io). The accompanying [traefik job](hashicorp/nomad/jobs/traefik.nomad) is deployed on provisioning Nomad.
3. I have updated the Nomad `server.conf` (see [`hashicorp/nomad.sh`](hashicorp/nomad.sh)) to give it the ability to pull Docker images from private GHCR repos by way of a GitHub Personal Access Token (PAT)
4. I have added Nomad/Vault integration. See [`hashicorp/nomad.sh`](hashicorp/nomad.sh) and [`hashicorp/vault.sh`](hashicorp/vault.sh)
5. I have added an [OpenTelemetry Collector job](hashicorp/nomad/jobs/otel-collector.nomad) to test the Vault/Nomad integration.
6. I have added a sample [2048-game](hashicorp/nomad/jobs/2048-game.nomad) job as a simple Nomad jobspec for testing purposes.

## Pre-requisites

* [Oracle VirtualBox](https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwjVuPag0oL0AhXFnrMKHRjODRYYABAAGgJxbg&ohost=www.google.com&cid=CAASEuRoonvAcnwV4Mde6j85eTiOEQ&sig=AOD64_1N8BIxbnQDEjTDYvtzMR78syE9Bg&q&adurl&ved=2ahUKEwiUpe6g0oL0AhVjTd8KHWTvAkEQ0Qx6BAgCEAE) (version 6.1.30 at the time of this writing)
* [Vagrant](https://www.vagrantup.com/) (version 2.2.19 at the time of this writing)
* [A GitHub Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## Quickstart

To get started:

1. Clone the repo

    ```bash
    git clone git@github.com:avillela/hashiqube.git
    ```

2. Start Vagrant

    ```bash
    cd hashiqube
    vagrant up
    ```

3. Access the Hashi tools

    The following tools are now accessible from your host machine

    * Vault: http://localhost:8200 (Get the login token by logging into the guest machine using `vagrant ssh` and running `cat /etc/vault/init.file | grep Root`)
    * Nomad: http://localhost:4646
    * Consul: http://localhost:8500
    * Traefik: http://traefik.localhost
    * Waypoint: https://${VAGRANT_IP}:9702 (Get the login token by logging into the guest machine using `vagrant ssh` and running `cat /home/vagrant/waypoint_user_token.txt`)

    If you'd like to SSH into the HashiQube VM, you can do so by running the following from a terminal window on your host machine.

    ```bash
    vagrant ssh
    ```

## Waypoint Notes and Gotchas

Waypoint requires a storage back-end. For this example, I used a MySQL DB as the back-end. This is why we deploy the [`my-sql.nomad`](hashicorp/nomad/jobs/my-sql.nomad) as part of the Nomad bootstrapping process. We also configure a  `host_volume` called `mysql` in `/etc/nomad/server.conf` on the VM. This is referenced by Waypoint when we run the install:

```
waypoint install -platform=nomad -nomad-dc=dc1 -accept-tos -nomad-host-volume="mysql"
```

Note how `-nomad-host-volume` points to `mysql`, which we defined in the nomad config.

Another thing worth mentioning is that you may notice after installing Waypoint, you'll see it running successfully in Nomad, but you'll also see the following error in the provisioning output following the Waypoint server install:

```
Error connecting to server: context deadline exceeded
```

This is fixed by running:

```
waypoint server bootstrap -server-addr=${VAGRANT_IP}:9701 -server-tls-skip-verify
```

I have no idea why we keep getting the first error, but the above command seems to fix things, so yay!

After Waypoint is bootstrapped, you can log in by:

```
waypoint login \
    -token=$(cat /home/vagrant/waypoint_user_token.txt) \
    ${VAGRANT_IP}

waypoint context verify
waypoint context list
```

## Detailed How-To Guides

For detailed tutorials that use this repo, please see the following blog posts on Medium:
* [Just-in-Time Nomad: Running Traefik on Nomad with HashiQube](https://adri-v.medium.com/just-in-time-nomad-running-traefik-on-hashiqube-7d6dfd8ef9d8)
* [Just-in-Time Nomad: Running the OpenTelemetry Collector on Hashicorp Nomad with HashiQube](https://adri-v.medium.com/just-in-time-nomad-running-the-opentelemetry-collector-on-hashicorp-nomad-with-hashiqube-4eaf009b8382)
* [Just-in-Time Nomad: Configuring Nomad/Vault Integration on HashiQube](https://adri-v.medium.com/just-in-time-nomad-configuring-hashicorp-nomad-vault-integration-on-hashiqube-388c14cb070a)

## Gotchas

### Unable to access guest machine IP

If you're unable to access the guest machine IP, change the static IP address in line 26 of the [`Vagrantfile`](Vagrantfile), as it may be the result of an IP collision. See [this issue](https://superuser.com/a/1016731) on StackExchange.
### DNS Resolution Issues with *.localhost

If you're using a Mac and are running into issues getting your machine to resolve `*.localhost`, try this: 

1. Install dnsmasq

    ```bash
    brew install dnsmasq
    ```

2. Configure

    Copy the sample config file to /usr/local/etc/dnsmasq.conf, and add address=/localhost/127.0.0.1 to it

    ```bash
    cp $(brew list dnsmasq | grep dnsmasq.conf) /usr/local/etc/dnsmasq.conf
    echo "address=/localhost/127.0.0.1" >> /usr/local/etc/dnsmasq.conf
    ```

    Restart dnsmasq services
    
    ```bash
    sudo brew services restart dnsmasq
    ```

    Add a resolver to allow OS X to resolve requests from `*.localhost`
    
    ```bash
    sudo mkdir /etc/resolver
    sudo touch /etc/resolver/localhost
    sudo echo "nameserver 127.0.0.1" >> /etc/resolver/localhost
    ```

3. Test
    
    Even though foo.localhost doesn’t exist, we should now be able to ping it, since it will map to 127.0.0.1, as per our configs above.
    
    ```bash
    ping foo.localhost
    ```

    Result:
    
    ```
    PING foo.localhost (127.0.0.1): 56 data bytes
    64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.035 ms
    64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.111 ms
    64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.092 ms
    ...
    — — foo.localhost ping statistics — -
    3 packets transmitted, 3 packets received, 0.0% packet loss
    round-trip min/avg/max/stddev = 0.035/0.079/0.111/0.032 ms
    ```

# References

Waypoint references:
* [Waypoint UI](https://learn.hashicorp.com/tutorials/waypoint/get-started-ui?in=waypoint/get-started-docker)
* [`waypoint install` command documentation](https://www.waypointproject.io/commands/install)
* [Waypoint Express Install - Nomad](https://www.waypointproject.io/docs/server/install#nomad-platform)
* [Deploy sample app to Nomad using Waypoint](https://learn.hashicorp.com/tutorials/waypoint/get-started-nomad?in=waypoint/get-started-nomad)
* [Waypoint Architecture](https://www.waypointproject.io/docs/internals/execution#most-advanced-cli-remote-server-remote-runner)
