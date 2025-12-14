#!/bin/bash

sudo -i

# Install prerequisites and update system
yum install -y epel-release
yum update -y

yum install -y nagios nagios-plugins-all nrpe httpd --skip-broken
yum install -y nagios-plugins-nrpe
# Set Nagios admin password
htpasswd -bc /etc/nagios/passwd nagiosadmin admin123

# Enable and start required services
systemctl enable httpd && systemctl start httpd
systemctl enable nagios && systemctl start nagios
systemctl start firewalld.service

# Configure firewall
firewall-cmd --add-service=http --permanent
firewall-cmd --add-port=5666/tcp --permanent
firewall-cmd --reload

# Add monitored hosts to Nagios configuration
cat > /etc/nagios/objects/clients.cfg <<'EOL'
# ========================================
# HOST DEFINITIONS
# ========================================
define host {
  use             linux-server
  host_name       db01
  alias           MariaDB Database Server
  address         192.168.56.15
}

define host {
  use             linux-server
  host_name       mc01
  alias           Memcached Server
  address         192.168.56.14
}

define host {
  use             linux-server
  host_name       rmq01
  alias           RabbitMQ Message Broker
  address         192.168.56.13
}

define host {
  use             linux-server
  host_name       app01
  alias           Tomcat Application Server
  address         192.168.56.12
}

define host {
  use             linux-server
  host_name       web01
  alias           Nginx Web Server
  address         192.168.56.11
}
EOL

# Add service definitions with systemd monitoring
cat > /etc/nagios/objects/services.cfg <<'EOL'
# ========================================
# SERVICE DEFINITIONS
# ========================================

# ========================================
# Host: db01 (MariaDB)
# ========================================
define service{
    use                     generic-service
    host_name               db01
    service_description     PING
    check_command           check_ping!100.0,20%!500.0,60%
}

define service{
    use                     generic-service
    host_name               db01
    service_description     MariaDB Service Status
    check_command           check_nrpe!check_mariadb
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    notification_interval   30
}

# ========================================
# Host: mc01 (Memcached)
# ========================================
define service{
    use                     generic-service
    host_name               mc01
    service_description     PING
    check_command           check_ping!100.0,20%!500.0,60%
}

define service{
    use                     generic-service
    host_name               mc01
    service_description     Memcached Service Status
    check_command           check_nrpe!check_memcached
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    notification_interval   30
}

# ========================================
# Host: rmq01 (RabbitMQ)
# ========================================
define service{
    use                     generic-service
    host_name               rmq01
    service_description     PING
    check_command           check_ping!100.0,20%!500.0,60%
}

define service{
    use                     generic-service
    host_name               rmq01
    service_description     RabbitMQ Service Status
    check_command           check_nrpe!check_rabbitmq
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    notification_interval   30
}

# ========================================
# Host: app01 (Tomcat)
# ========================================
define service{
    use                     generic-service
    host_name               app01
    service_description     PING
    check_command           check_ping!100.0,20%!500.0,60%
}

define service{
    use                     generic-service
    host_name               app01
    service_description     Tomcat Service Status
    check_command           check_nrpe!check_tomcat
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    notification_interval   30
}

# ========================================
# Host: web01 (Nginx)
# ========================================
define service{
    use                     generic-service
    host_name               web01
    service_description     PING
    check_command           check_ping!100.0,20%!500.0,60%
}

define service{
    use                     generic-service
    host_name               web01
    service_description     Nginx Service Status
    check_command           check_nrpe!check_nginx
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    notification_interval   30
}
EOL

# Add NRPE command definition
cat >> /etc/nagios/objects/commands.cfg <<'EOL'

# ========================================
# NRPE COMMAND FOR REMOTE MONITORING
# ========================================
define command {
    command_name    check_nrpe
    command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
EOL

# Remove duplicate cfg_file entries if exist
sed -i '/^cfg_file=.*services.cfg/d' /etc/nagios/nagios.cfg
sed -i '/^cfg_file=.*clients.cfg/d' /etc/nagios/nagios.cfg

# Update Nagios configuration
echo "cfg_file=/etc/nagios/objects/services.cfg" >> /etc/nagios/nagios.cfg
echo "cfg_file=/etc/nagios/objects/clients.cfg" >> /etc/nagios/nagios.cfg

# Verify Nagios configuration
nagios -v /etc/nagios/nagios.cfg

# Restart Nagios to apply changes
systemctl restart nagios

# Display access information
echo "========================================="
echo "Nagios Installation Completed!"
echo "========================================="
echo "Web UI: http://192.168.56.10/nagios"
echo "Username: nagiosadmin"
echo "Password: admin123"
echo "========================================="
echo "Monitored Hosts:"
echo "  - db01 (192.168.56.15) - MariaDB"
echo "  - mc01 (192.168.56.14) - Memcached"
echo "  - rmq01 (192.168.56.13) - RabbitMQ"
echo "  - app01 (192.168.56.12) - Tomcat"
echo "  - web01 (192.168.56.11) - Nginx"
echo "========================================="
