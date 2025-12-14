Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  # Function to configure clients for NRPE and monitoring
  def configure_client(config, name, ip, memory, script_path)
    config.vm.define name do |client|
      client.vm.box = "eurolinux-vagrant/centos-stream-9"
      client.vm.hostname = name
      client.vm.network "private_network", ip: ip
      client.vm.provider "virtualbox" do |vb|
        vb.memory = memory
      end

      # Install and configure NRPE
      client.vm.provision "shell", path: script_path, privileged: true
      client.vm.provision "shell", inline: <<-SHELL
        sudo yum install -y epel-release
        sudo yum update -y
        sudo yum install -y nrpe nagios-plugins-all --skip-broken
        
        # Create systemd monitoring script
        cat > /usr/lib64/nagios/plugins/check_systemd_service.sh <<'EOF'
#!/bin/bash
SERVICE=$1
if systemctl is-active --quiet $SERVICE; then
    echo "OK: $SERVICE is active"
    exit 0
else
    echo "CRITICAL: $SERVICE is not active"
    exit 2
fi
EOF
        chmod +x /usr/lib64/nagios/plugins/check_systemd_service.sh
        
        # Add systemd monitoring commands to nrpe.cfg
        cat >> /etc/nagios/nrpe.cfg <<'EOF'

# Systemd Service Monitoring
command[check_mariadb]=/usr/lib64/nagios/plugins/check_systemd_service.sh mariadb.service
command[check_memcached]=/usr/lib64/nagios/plugins/check_systemd_service.sh memcached.service
command[check_rabbitmq]=/usr/lib64/nagios/plugins/check_systemd_service.sh rabbitmq-server.service
command[check_tomcat]=/usr/lib64/nagios/plugins/check_systemd_service.sh tomcat.service
EOF
        
        echo "allowed_hosts=127.0.0.1,192.168.56.10" >> /etc/nagios/nrpe.cfg
        sudo systemctl enable nrpe && sudo systemctl restart nrpe
        systemctl start firewalld.service
        firewall-cmd --add-port=5666/tcp --permanent
        firewall-cmd --reload
      SHELL
    end
  end

  ## DB VM
  configure_client(config, "db01", "192.168.56.15", 2048, "mariadb.sh")

  ## Memcache VM
  configure_client(config, "mc01", "192.168.56.14", 900, "memcached.sh")

  ## RabbitMQ VM
  configure_client(config, "rmq01", "192.168.56.13", 600, "rabbitmq.sh")

  ## Tomcat VM
  configure_client(config, "app01", "192.168.56.12", 4200, "tomcat.sh")

  ## Nginx VM
  config.vm.define "web01" do |web01|
    web01.vm.box = "ubuntu/jammy64"
    web01.vm.hostname = "web01"
    web01.vm.network "private_network", ip: "192.168.56.11"
    web01.vm.provider "virtualbox" do |vb|
      vb.gui = true
      vb.memory = "800"
    end

    # Provision services and NRPE
    web01.vm.provision "shell", path: "nginx.sh", privileged: true
    web01.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y nagios-nrpe-server nagios-plugins
      
      # Create systemd monitoring script
      cat > /usr/lib/nagios/plugins/check_systemd_service.sh <<'EOF'
#!/bin/bash
SERVICE=$1
if systemctl is-active --quiet $SERVICE; then
    echo "OK: $SERVICE is active"
    exit 0
else
    echo "CRITICAL: $SERVICE is not active"
    exit 2
fi
EOF
      chmod +x /usr/lib/nagios/plugins/check_systemd_service.sh
      
      # Add systemd monitoring command
      cat >> /etc/nagios/nrpe.cfg <<'EOF'

# Systemd Service Monitoring
command[check_nginx]=/usr/lib/nagios/plugins/check_systemd_service.sh nginx.service
EOF
      
      echo "allowed_hosts=127.0.0.1,192.168.56.10" >> /etc/nagios/nrpe.cfg
      systemctl enable nagios-nrpe-server && systemctl restart nagios-nrpe-server
      ufw allow 5666
    SHELL
  end

  # Nagios VM
  config.vm.define "nagios" do |nagios|
    nagios.vm.box = "eurolinux-vagrant/centos-stream-9"
    nagios.vm.hostname = "nagios"
    nagios.vm.network "private_network", ip: "192.168.56.10"
    nagios.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end

    # Use external shell script for provisioning
    nagios.vm.provision "shell", path: "nagios.sh"
  end
end
