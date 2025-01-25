#!/bin/bash

sudo -i

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

# Add service definitions
cat <<EOL >> /etc/nagios/objects/services.cfg
define service{
    use                     generic-service
    host_name               db01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               mc01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               rmq01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               app01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               web01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}
EOL

# Add NRPE command definition
cat <<EOL >> /etc/nagios/objects/commands.cfg
define command {
    command_name    check_nrpe
    command_line    \$USER1\$/check_nrpe -H \$HOSTADDRESS\$ -c \$ARG1\$
}
EOL

# Update Nagios configuration
echo "cfg_file=/etc/nagios/objects/services.cfg" >> /etc/nagios/nagios.cfg
echo "cfg_file=/etc/nagios/objects/clients.cfg" >> /etc/nagios/nagios.cfg

# Restart Nagios to apply changes
systemctl restart nagios

# Confirmation message
echo "Nagios services and commands configuration updated successfully."
