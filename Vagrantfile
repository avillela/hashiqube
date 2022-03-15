# -*- mode: ruby -*-
# vi: set ft=ruby :

# create local domain name e.g user.local.dev
user = ENV["USER"].downcase
fqdn = ENV["fqdn"] || "0"

# https://www.virtualbox.org/manual/ch08.html
vbox_config = [
  { '--memory' => '4096' },
  { '--cpus' => '2' },
  { '--cpuexecutioncap' => '100' },
  { '--biosapic' => 'x2apic' },
  { '--ioapic' => 'on' },
  { '--largepages' => 'on' },
  { '--natdnshostresolver1' => 'on' },
  { '--natdnsproxy1' => 'on' },
  { '--nictype1' => 'virtio' },
  { '--audio' => 'none' },
]

# machine(s) hash
machines = [
  {
    :name => "hashiqube.#{fqdn}",
    :ip => '192.168.56.192',
    :ssh_port => '2255',
    :vbox_config => vbox_config,
    :synced_folders => [
      { :vm_path => '/data', :ext_rel_path => './', :vm_owner => 'ubuntu' },
    ],
  },
]


Vagrant::configure("2") do |config|

  # check for vagrant version
  Vagrant.require_version ">= 1.9.7"

  if Vagrant::Util::Platform.windows?
    COMMAND_SEPARATOR = "&"
  else
    COMMAND_SEPARATOR = ";"
  end

  machines.each_with_index do |machine, index|

    config.vm.box = "ubuntu/bionic64"
    config.vm.define machine[:name] do |config|

      config.ssh.forward_agent = true
      config.ssh.insert_key = true
      config.vm.network "private_network", ip: machine[:ip]
      config.vm.network "forwarded_port", guest: 22, host: machine[:ssh_port], id: 'ssh', auto_correct: true

      if machines.size == 1 # only expose these ports if 1 machine, else conflicts
        config.vm.network "forwarded_port", guest: 8200, host: 8200 # vault
        config.vm.network "forwarded_port", guest: 4646, host: 4646 # nomad
        config.vm.network "forwarded_port", guest: 9702, host: 9702 # waypoint
        config.vm.network "forwarded_port", guest: 8500, host: 8500 # consul
        config.vm.network "forwarded_port", guest: 8600, host: 8600, protocol: 'udp' # consul dns
        config.vm.network "forwarded_port", guest: 3306, host: 3306 # mysql
        config.vm.network "forwarded_port", guest: 3333, host: 3333 # docsify
        config.vm.network "forwarded_port", guest: 80, host: 80 # traefik dashboard
        config.vm.network "forwarded_port", guest: 8082, host: 8082 # traefik metrics
      end

      config.vm.hostname = "#{machine[:name]}"

      unless machine[:vbox_config].nil?
        config.vm.provider :virtualbox do |vb|
          machine[:vbox_config].each do |hash|
            hash.each do |key, value|
              vb.customize ['modifyvm', :id, "#{key}", "#{value}"]
            end
          end
        end
      end

      # mount the shared folder inside the VM
      unless machine[:synced_folders].nil?
        machine[:synced_folders].each do |folder|
          config.vm.synced_folder "#{folder[:ext_rel_path]}", "#{folder[:vm_path]}", owner: "#{folder[:vm_owner]}", mount_options: ["dmode=777,fmode=777"]
        end
      end

      # vagrant up --provision-with bootstrap to only run this on vagrant up
      config.vm.provision "bootstrap", preserve_order: true, type: "shell", privileged: true, inline: <<-SHELL
        echo -e '\e[38;5;198m'"BEGIN BOOTSTRAP $(date '+%Y-%m-%d %H:%M:%S')"
        echo -e '\e[38;5;198m'"running vagrant as #{user}"
        echo -e '\e[38;5;198m'"vagrant IP "#{machine[:ip]}
        echo -e '\e[38;5;198m'"vagrant fqdn #{machine[:name]}"
        echo -e '\e[38;5;198m'"vagrant index #{index}"
        cd ~\n
        grep -q "VAGRANT_IP=#{machine[:ip]}" /etc/environment
        if [ $? -eq 1 ]; then
          echo "VAGRANT_IP=#{machine[:ip]}" >> /etc/environment
        else
          sed -i "s/VAGRANT_INDEX=.*/VAGRANT_INDEX=#{index}/g" /etc/environment
        fi
        grep -q "VAGRANT_INDEX=#{index}" /etc/environment
        if [ $? -eq 1 ]; then
          echo "VAGRANT_INDEX=#{index}" >> /etc/environment
        else
          sed -i "s/VAGRANT_INDEX=.*/VAGRANT_INDEX=#{index}/g" /etc/environment
        fi
        # install applications
        export DEBIAN_FRONTEND=noninteractive
        export PATH=$PATH:/root/.local/bin
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes update -o Acquire::CompressionTypes::Order::=gz
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes upgrade
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install swapspace jq curl unzip software-properties-common bzip2 git make python3-pip python3-dev python3-virtualenv golang-go apt-utils
        sudo -E -H pip3 install pip --upgrade
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes autoremove
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes clean
        sudo rm -rf /var/lib/apt/lists/partial
        echo -e '\e[38;5;198m'"END BOOTSTRAP $(date '+%Y-%m-%d %H:%M:%S')"
      SHELL

      # install vault
      # vagrant up --provision-with vault to only run this on vagrant up
      config.vm.provision "vault", type: "shell", preserve_order: true, privileged: true, path: "hashicorp/vault.sh"

      # install consul
      # vagrant up --provision-with consul to only run this on vagrant up
      config.vm.provision "consul", type: "shell", preserve_order: true, privileged: true, path: "hashicorp/consul.sh"

      # install docker
      # vagrant up --provision-with docker to only run this on vagrant up
      config.vm.provision "docker", type: "shell", preserve_order: true, privileged: true, path: "docker/docker.sh"

      # install nomad
      # vagrant up --provision-with nomad to only run this on vagrant up
      config.vm.provision "nomad", type: "shell", preserve_order: true, privileged: true, path: "hashicorp/nomad.sh"

      # install waypoint
      # vagrant up --provision-with waypoint to only run this on vagrant up
      # config.vm.provision "waypoint", type: "shell", preserve_order: true, privileged: true, path: "hashicorp/waypoint.sh"
           
      # docsify
      # vagrant up --provision-with docsify to only run this on vagrant up
      config.vm.provision "docsify", type: "shell", preserve_order: true, privileged: false, path: "docsify/docsify.sh"

      # vagrant up --provision-with bootstrap to only run this on vagrant up
      config.vm.provision "welcome", preserve_order: true, type: "shell", privileged: true, inline: <<-SHELL
        echo -e '\e[38;5;198m'"HashiQube has now been provisioned, and your services should be running."
        echo -e '\e[38;5;198m'"Below are some links for you to get started."
        echo -e '\e[38;5;198m'"Main documentation http://localhost:3333 Open this first."
        echo -e '\e[38;5;198m'"Vault admin console http://localhost:8200 with $(cat /etc/vault/init.file | grep Root)"
        echo -e '\e[38;5;198m'"Consul admin console http://localhost:8500"
        echo -e '\e[38;5;198m'"Nomad admin console http://localhost:4646"
        echo -e '\e[38;5;198m'"Traefik dashboard http://traefik.localhost"
        # echo -e '\e[38;5;198m'"Waypoint Server https://${VAGRANT_IP}:9702 with $(cat /vagrant/hashicorp/waypoint/waypoint_user_token.txt)"
      SHELL

    end
  end
end