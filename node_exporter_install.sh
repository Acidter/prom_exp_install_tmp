#!/bin/bash
set -xe

node_exporter_version=1.1.2
node_exporter_base_url=https://github.com/prometheus/node_exporter/releases/download/
node_exporter_get_url=${node_exporter_base_url}v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-amd64.tar.gz
higs_ip=$(curl -s http://checkip.amazonaws.com)
node_exp_port=9101

mkdir -p ~/tmp_deb
wget ${node_exporter_get_url} -O ~/tmp_deb/node_exporter-${node_exporter_version}.linux-amd64.tar.gz
mkdir ~/tmp_deb/node_exporter_bin
tar -xvf ~/tmp_deb/node_exporter-${node_exporter_version}.linux-amd64.tar.gz -C ~/tmp_deb/node_exporter_bin/
mv tmp_deb/node_exporter_bin/node_exporter-${node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/
rm -rfv ~/tmp_deb
useradd -rs /bin/false node-exp

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
Type=simple
User=node-exp
Group=node-exp
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

curl -s ${higs_ip}:${node_exp_port}