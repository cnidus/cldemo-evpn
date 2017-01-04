#!/bin/bash

#This file is transferred to the Cumulus VX and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "  Running Switch Post Config"
echo "#################################"
sudo su

echo "  adding fake cl-acltool..."
echo -e "#!/bin/bash\nexit 0" > /bin/cl-acltool
chmod 755 /bin/cl-acltool

echo "  adding fake cl-license..."
echo -e "#!/bin/bash\nexit 0" > /bin/cl-license
chmod 755 /bin/cl-license

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir -p /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus/.ssh
chown cumulus:cumulus -R /home/cumulus/.ssh
echo "This is a fake license" > /etc/cumulus/.license.txt

## Make onie reinstalls work. Note that installing from onie will undo these changes.
mkdir /tmp/foo
mount LABEL=ONIE-BOOT /tmp/foo
sed -i 's/eth0/eth1/g' /tmp/foo/grub/grub.cfg
sed -i 's/eth0/eth1/g' /tmp/foo/onie/grub/grub-extra.cfg
umount /tmp/foo

cp /home/vagrant/interfaces /etc/network/interfaces
cp /home/vagrant/daemons /etc/quagga/daemons
cp /home/vagrant/Quagga.conf /etc/quagga/Quagga.conf

ifreload -a

## Enabling Quagga
sed -i 's/zebra=no/zebra=yes/g' /etc/quagga/daemons
sed -i 's/bgpd=no/bgpd=yes/g' /etc/quagga/daemons
systemctl enable quagga.service
systemctl start quagga.service

echo grub-pc grub-pc/install_devices select /dev/sda | sudo debconf-set-selections

#Upgrading Quagga for EVPN
sed -i 's/#deb     http:\/\/repo3.cumulusnetworks.com\/repo CumulusLinux-3-early-access cumulus/deb     http:\/\/repo3.cumulusnetworks.com\/repo CumulusLinux-3-early-access cumulus/' /etc/apt/sources.list
sed -i 's/#deb-src http:\/\/repo3.cumulusnetworks.com\/repo CumulusLinux-3-early-access cumulus/deb-src http:\/\/repo3.cumulusnetworks.com\/repo CumulusLinux-3-early-access cumulus/' /etc/apt/sources.list
apt-get update
apt-get install cumulus-evpn
apt-get upgrade -y --force-yes

echo "#################################"
echo "   Finished"
echo "#################################"
