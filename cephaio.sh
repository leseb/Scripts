#!/bin/bash

git clone https://github.com/ceph/ceph-ansible.git
sed -i '' 's/fsid: /fsid: 4a158d27-f750-41d5-9e7f-26ce4c9d2d45 /' ceph-ansible/group_vars/all
sed -i '' 's/monitor_secret: /monitor_secret: AQAWqilTCDh7CBAAawXt6kyTgLFCxSvJhTEmuw== /' ceph-ansible/group_vars/mons

cat > Vagrantfile << EOF
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-i386-vagrant-disk1.box"
  config.vm.define :cephaio do |cephaio|
    cephaio.vm.network :private_network, ip: "192.168.0.2"
    cephaio.vm.host_name = "cephaio"
    (0..2).each do |d|
      cephaio.vm.provider :virtualbox do |vb|
        vb.customize [ "createhd", "--filename", "disk-#{d}", "--size", "1000" ]
        vb.customize [ "storageattach", :id, "--storagectl", "SATA Controller", "--port", 3+d, "--device", 0, "--type", "hdd", "--medium", "disk-#{d}.vdi" ]
        vb.customize [ "modifyvm", :id, "--memory", "512" ]
      end
    end
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = "ceph-ansible/site.yml"
      ansible.groups = {
        "mons" => ["cephaio"],
        "osds" => ["cephaio"],
        "mdss" => ["cephaio"],
        "rgws" => ["cephaio"]
      }
    end
  end
end
EOF
vagrant up
