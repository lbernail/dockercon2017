#!/bin/bash
set -e

echo "Setting hostname"
echo ${TF_HOSTNAME} > /etc/hostname
echo "${TF_HOST_IP} ${TF_HOSTNAME}" >> /etc/hosts
hostname ${TF_HOSTNAME}

echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6

echo "Installing dependencies..."
apt-get update
apt-get install -y tcpdump ethtool vim curl iputils-arping bridge-utils iptables iproute libjson-c2 logrotate python python-ipaddr qemu

echo "Downloading ubuntu and linuxkit img"
curl -sSLo /home/${TF_USER}/wheezy.qcow2 https://people.debian.org/~aurel32/qemu/i386/debian_wheezy_i386_standard.qcow2

mkdir -p /home/${TF_USER}/linuxkit/bin
for f in bin/linuxkit linuxkit-cmdline  linuxkit-initrd.img  linuxkit-kernel
do
    curl -sSLo /home/${TF_USER}/linuxkit/$f http://dockercon.awsdemo.d2-si.eu.s3-website-eu-west-1.amazonaws.com/$f
done
chmod +x /home/${TF_USER}/linuxkit/bin/*
cp /home/${TF_USER}/linuxkit/bin/* /usr/local/bin

echo "Adding a few helpers for demo purposes"
curl -sSL https://github.com/lbernail/dockercon2017/archive/master.tar.gz | tar -xzf - --strip-components=1 -C /home/${TF_USER}
chown -R ${TF_USER}:${TF_USER} /home/${TF_USER}

echo "Installing cumulus Quagga"
apt-get install -y iproute libsnmp30
curl -sSLo /tmp/quagga.deb http://repo3.cumulusnetworks.com/repo/pool/cumulus/q/quagga/quagga_1.0.0+cl3eau8_amd64.deb
curl -sSLo /tmp/quagga-dbg.deb http://repo3.cumulusnetworks.com/repo/pool/cumulus/q/quagga/quagga-dbg_1.0.0+cl3eau8_amd64.deb
curl -sSLo /tmp/quagga-doc.deb http://repo3.cumulusnetworks.com/repo/pool/cumulus/q/quagga/quagga-doc_1.0.0+cl3eau8_all.deb

dpkg -i /tmp/quagga*.deb

echo "Generating Quagga configuration"
cat <<EOF > /etc/quagga/Quagga.conf
${TF_QUAGGA_CONF}
EOF
cat <<EOF > /etc/quagga/daemons
zebra=yes
bgpd=yes
ospfd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
EOF
cat <<EOF > /etc/quagga/debian.conf
vtysh_enable=yes 
zebra_options=" --daemon -A 127.0.0.1 "
bgpd_options=" --daemon -A 127.0.0.1 "
EOF

systemctl enable quagga
systemctl start quagga
