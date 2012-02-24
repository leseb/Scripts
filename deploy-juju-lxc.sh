#!/bin/bash

echo "Dependencies installation"
sudo apt-get update && sudo apt-get install libvirt-bin lxc apt-cacher-ng libzookeeper-java zookeeper juju
if [ $? -eq 1 ] ; then
        echo "Create a SSH key pair"
        ssh-keygen -t rsa
        juju bootstrap 2&1 > /dev/null

        echo "Generate your environment"
        cat > ~/.juju/environement.yaml << EOF
        environments:
                sample:
                type: local
                control-bucket: juju-a14dfae3830142d9ac23c499395c2785999
                admin-secret: 6608267bbd6b447b8c90934167b2a294999
                default-series: oneiric
                juju-origin: distro
                data-dir: /home/jorge/whatever
        EOF
        echo "Bootstrapping your environement"
        juju bootstrap
        if [ $? -eq 1 ] ; then
                echo "Deploying Wordpress"
                juju deploy --repository=/usr/share/doc/juju/exampless local:mysql
                juju deploy --repository=/usr/share/doc/juju/examples/ local:wordpress
                juju add-relation wordpress mysql
                juju expose wordpress
                if [ $? -eq 1 ] ; then
                        IP_PUBLIC=$(juju status | grep public-address | sed -n '2p' | awk '{print $2}')
                        if [[ ${IP_PUBLIC} ~= (null) ]] ; then
                                echo "LXC container error, please reboot your machine and re-launch the script."
                        else
                                echo -e "Installation finished.$\nConfigure your Wordpress here http://$IP_PUBLIC "
                        fi
                fi
        fi
fi