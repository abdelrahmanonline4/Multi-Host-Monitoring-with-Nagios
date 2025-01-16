#!/bin/bash

# Elevate privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install prerequisites and update system
yum install -y epel-release
yum update -y

yum install -y nagios nagios-plugins-all nrpe httpd --skip-broken

# Enable and start required services
systemctl enable httpd && systemctl start httpd
systemctl enable nagios && systemctl start nagios
systemctl start firewalld.service

# Configure firewall
firewall-cmd --add-service=http --permanent
firewall-cmd --add-port=5666/tcp --permanent
firewall-cmd --reload

# Add monitored hosts to Nagios configuration
cat <<EOL >> /etc/nagios/objects/clients.cfg
define host {
  use             linux-server
  host_name       db01
  address         192.168.56.15
}

define host {
  use             linux-server
  host_name       mc01
  address         192.168.56.14
}

define host {
  use             linux-server
  host_name       rmq01
  address         192.168.56.13
}

define host {
  use             linux-server
  host_name       app01
  address         192.168.56.12
}

define host {
  use             linux-server
  host_name       web01
  address         192.168.56.11
}
EOL


echo "cfg_file=/etc/nagios/objects/clients.cfg" >> /etc/nagios/nagios.cfg

# Restart Nagios to apply changes
systemctl restart nagios

# Confirmation message
echo "Nagios installation and configuration complete."
