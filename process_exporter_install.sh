#!/bin/bash
set -xe

process_exporter_version=0.5.0
process_exporter_base_url=https://github.com/ncabatoff/process-exporter/releases/download/
process_exporter_get_url=${process_exporter_base_url}v${process_exporter_version}/process-exporter-${process_exporter_version}.linux-amd64.tar.gz
higs_ip=$(curl -s http://checkip.amazonaws.com)
process_exp_port=9256

mkdir -p ~/tmp_deb
wget ${process_exporter_get_url} -O tmp_deb/process_exporter-${process_exporter_version}.linux-amd64.tar.gz
mkdir ~/tmp_deb/process_exporter_bin
tar -xvf ~/tmp_deb/process_exporter-${process_exporter_version}.linux-amd64.tar.gz -C ~/tmp_deb/process_exporter_bin/
mv tmp_deb/process_exporter_bin/process-exporter-${process_exporter_version}.linux-amd64/process-exporter /usr/local/bin/
rm -rfv ~/tmp_deb

cat <<EOF > /etc/systemd/system/process_exporter.service
[Unit]
Description=Process Exporter for Prometheus

[Service]
User=root
Type=simple
ExecStart=/usr/local/bin/process-exporter \
  --config.path /etc/process-exporter.yml \
  --web.listen-address=${higs_ip}:${process_exp_port}
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/process-exporter.yml
process_names:
  - name: "{{.Matches}}"
    cmdline:
    - 'gnats|socket|api|news|ad|blacklist|clan|friends|leaderboards|mail|news|offer|push|quest|updater|higgs'
EOF

systemctl daemon-reload
systemctl enable --now process_exporter
systemctl status process_exporter
