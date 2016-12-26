#!/bin/bash

# Add OpenNebula repository
cat << EOT > /etc/yum.repos.d/opennebula.repo
[opennebula]
name=opennebula
baseurl=http://downloads.opennebula.org/repo/5.2/CentOS/7/x86_64
enabled=1
gpgcheck=0
EOT

# Disable selinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# Add EPEL and qemu-ev repositories
yum install -y \
    epel-release\
    centos-release-qemu-ev

# Install OpenNebula packages
yum install -y \
    opennebula-server \
    opennebula-sunstone \
    opennebula-ruby \
    opennebula-gate \
    opennebula-flow \
    opennebula-node-kvm

# Run install_gems
/usr/share/one/install_gems --yes

# Set default disk format to qcow2
sed -i 's/driver = "raw"/driver = "qcow2"/' /etc/one/vmm_exec/vmm_exec_kvm.conf

# Set default network driver to virtio
echo 'NIC     = [ model = "virtio" ]' >> /etc/one/vmm_exec/vmm_exec_kvm.conf

# Set default disk driver to virtio
sed -i 's/^DEFAULT_DEVICE_PREFIX.*$/DEFAULT_DEVICE_PREFIX = "vd"/' /etc/one/oned.conf

# Scheduler interval and MAX_HOST to 5
sed -i 's/^SCHED_INTERVAL.*$/SCHED_INTERVAL = 5/' /etc/one/sched.conf
sed -i 's/^MAX_HOST.*$/MAX_HOST = 5/' /etc/one/sched.conf

# Add first boot script
chmod +x /etc/rc.d/rc.local
echo "[ -f /firstboot-opennebula.sh ] && /firstboot-opennebula.sh" >> /etc/rc.d/rc.local

