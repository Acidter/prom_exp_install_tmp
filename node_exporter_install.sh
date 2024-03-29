#!/bin/bash
set -xe

node_exporter_version=1.7.0
node_exporter_base_url=https://github.com/prometheus/node_exporter/releases/download/
node_exporter_get_url=${node_exporter_base_url}v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-amd64.tar.gz
higs_ip=$(ip route get 1.1.1.1 | awk '$6 ~ /src/ {print $7}')
node_exp_port=9101
node_exp_user=prometheus-exporter-user

mkdir -p ~/tmp_deb
wget ${node_exporter_get_url} -O ~/tmp_deb/node_exporter-${node_exporter_version}.linux-amd64.tar.gz
mkdir ~/tmp_deb/node_exporter_bin
tar -xvf ~/tmp_deb/node_exporter-${node_exporter_version}.linux-amd64.tar.gz -C ~/tmp_deb/node_exporter_bin/
mv ~/tmp_deb/node_exporter_bin/node_exporter-${node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/
rm -rfv ~/tmp_deb
useradd -rs /bin/false ${node_exp_user}

mkdir -v /var/lib/node_exporter
chown -R ${node_exp_user}:${node_exp_user} /var/lib/node_exporter 

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
Type=simple
User=${node_exp_user}
Group=${node_exp_user}
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.systemd.unit-exclude='.+\\.(automount|device|mount|scope|slice)' \
    --collector.systemd.unit-include='(ll-.+|gnats).+' \
    --collector.systemd.enable-task-metrics \
    --collector.systemd.enable-start-time-metrics \
    --collector.systemd.enable-restarts-metrics \
    --collector.processes \
    --collector.textfile \
    --collector.textfile.directory=/var/lib/node_exporter \
    --web.listen-address=${higs_ip}:${node_exp_port} \
    --web.telemetry-path=/metrics

SyslogIdentifier=node_exporter
Restart=always
RestartSec=1
StartLimitInterval=0

ProtectHome=yes
NoNewPrivileges=yes

ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter
systemctl status node_exporter
