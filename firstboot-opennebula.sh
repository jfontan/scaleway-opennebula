#!/bin/bash

SCRIPT_PATH="$0"

# Wait until ssh is ready
while ! (ssh-keyscan localhost | grep localhost -q); do
    echo "Waiting for ssh" 1>&2
    sleep 1
done

# Get ssh fingerprint from localhost so it is not asked
su oneadmin -c "ssh-keyscan localhost > ~/.ssh/known_hosts"

# Generate new password
PASSWORD=$(date | md5sum | cut -d' ' -f 1)

# Write new credentials
echo "oneadmin:$PASSWORD" > /var/lib/one/.one/one_auth

# Enable and start services
systemctl enable libvirtd --now
systemctl enable opennebula --now

# Wait for OpenNebula daemon to be ready
while ! oneuser show > /dev/null; do
    sleep 1
done

systemctl enable opennebula-sunstone --now
systemctl enable opennebula-flow --now
systemctl enable opennebula-gate --now

# Change datastore drivers
EDITOR="sed -i 's/ssh/qcow2/'" onedatastore update 0
EDITOR="sed -i 's/ssh/qcow2/'" onedatastore update 1

# Create network
cat << EOT > /tmp/network
NAME=net
VN_MAD=fw
BRIDGE="virbr0"
DNS="8.8.8.8"
GATEWAY="192.168.122.1"
NETWORK_ADDRESS="192.168.122.0"
NETWORK_MASK="255.255.255.0"
EOT

onevnet create /tmp/network
onevnet addar net --ip 192.168.122.50 --size 200

onehost create localhost --im kvm --vm kvm

IP=$(scw-metadata PUBLIC_IP_ADDRESS)

(
echo ""
echo "OpenNebula is ready. You can connect to http://$IP:9869"
echo "use the following credentials:"
echo ""
echo "Username: oneadmin"
echo "Password: $PASSWORD"
echo ""
) > /etc/motd

rm -f $SCRIPT_PATH

