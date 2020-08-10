#/bin/sh

yum update -y
yum install git -y
yum install python -y
yum install python-pip -y
pip install supervisor
iptables --flush
usermod -aG wheel ec2-user

cd /home/ec2-user
mkdir fxserver
cd fxserver
mkdir server
mkdir server-data
wget -P /home/ec2-user/fxserver/server http://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/2802-a203581ad20c36ab2f8688bbf2ec8660cbb8e1c9/fx.tar.xz
cd /home/ec2-user/fxserver/server && tar -xf fx.tar.xz
cd /home/ec2-user/fxserver/server-data
git clone https://github.com/citizenfx/cfx-server-data /home/ec2-user/fxserver/server-data

# Supervisor
mkdir -p /etc/supervisor/conf.data
echo_supervisord_conf > /etc/supervisor/supervisord.conf

sed -i '0,/^;files = relative\/directory\/\*.ini/s//[include]\nfiles=conf.d\/\*.conf/' /etc/supervisor/supervisord.conf

cat > /etc/systemd/system/supervisord.service << EOF
[Unit]
Description=Supervisor daemon
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf
ExecStop=/usr/local/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/local/bin/supervisorctl $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
Alias=supervisord.service
EOF

cat > /etc/supervisor/conf.d/fivem_script.conf << EOF
[program:fivem_script]
directory=/home/ec2-user/fxserver/server-data
command=/home/ec2-user/fxserver/server/run.sh +exec server.cfg
autostart=true
autorestart=true

stderr_logfile=/var/log/fivem/fivem_err.log
stdout_logfile=/var/log/fivem/fivem_out.log
EOF

mkdir /var/log/fivem

supervisorctl reread
supervisorctl update
systemctl enable supervisorctl
systemctl restart supervisord.service