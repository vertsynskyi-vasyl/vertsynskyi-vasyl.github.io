#!/bin/bash
replace-config-value() {
    # $1 - config key
    # $2 - config new value
    # $3 - config file name 
    sudo sed -i "s/#$1/$1/1" $3 # uncomment config value first
    sudo sed -i "s/\($1 *= *\).*/\1$2/" $3 # set config value
}

export SONAR_HOME=/opt/sonarqube

sudo hostnamectl set-hostname ${nodename}

# Create sonarqube user
sudo groupadd -r sonar
sudo useradd -r -c "Sonar System User" -d $SONAR_HOME -g sonar -s /bin/bash sonar
echo ${server_user_password} | passwd sonar
sudo usermod -a -G sonar ec2-user

# Create Swap
sudo fallocate -l 1G /swap
sudo mkswap /swap
sudo swapon /swap
sudo chmod 600 /swap

# Install OpenJDK
sudo apt update && sudo apt install \
    openjdk-17-jdk unzip software-properties-common wget -y

# Install SonarQube
wget -O sonar.zip https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${sonarqube_version}.zip
unzip -o sonar.zip && rm -f sonar.zip
sudo mv sonarqube-${sonarqube_version} $SONAR_HOME
sudo chown -R sonar:sonar $SONAR_HOME
sudo chmod -R 775 $SONAR_HOME

# Configure SonarQube server
replace-config-value "sonar\.jdbc\.username" "${db_user}" $SONAR_HOME/conf/sonar.properties
replace-config-value "sonar\.jdbc\.password" "${db_pass}" $SONAR_HOME/conf/sonar.properties
replace-config-value "sonar\.web\.port" "8080" $SONAR_HOME/conf/sonar.properties
replace-config-value "sonar\.web\.javaAdditionalOpts" "-server" $SONAR_HOME/conf/sonar.properties
sudo sed -i "s/#sonar\.jdbc\.url=jdbc:postgresql.*/sonar\.jdbc\.url=jdbc:postgresql:\/\/${db_endpoint}\/${db_name}/g" $SONAR_HOME/conf/sonar.properties

# Configure system
cat << EOF | sudo tee /etc/sysctl.d/99-sonarqube.conf
vm.max_map_count=524288
fs.file-max=131072
EOF
sudo sysctl -p /etc/sysctl.d/99-sonarqube.conf
#
cat << EOF | sudo tee /etc/security/limits.d/99-sonarqube.conf
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF
sudo ulimit -n 131072
sudo ulimit -u 8192

# Create systemd service
cat << EOF | sudo tee /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Environment=JAVA_HOME=$JAVA_HOME
Environment=ES_JAVA_HOME=$JAVA_HOME
Type=forking
ExecStart=$SONAR_HOME/bin/linux-x86-64/sonar.sh start
ExecStop=$SONAR_HOME/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now sonarqube.service

