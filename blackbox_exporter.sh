#!/bin/bash
set -xe

metrics_ip_arg=$1 # 'local' or 'external'
icmp_target_ip=$2 # check
bb_exp_port=9115

if [[ "$metrics_ip_arg" == "local" ]]; then
    used_ip=$(ip a | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | grep 10.*.)
elif [[ "$metrics_ip_arg" == "external" ]]
    used_ip=$(curl -s http://checkip.amazonaws.com)
fi

bb_exp_version=0.22.0
bb_exp_base_url=https://github.com/prometheus/blackbox_exporter/releases/download/
bb_ext_get_url=${bb_exp_base_url}v${bb_exp_version}/blackbox_exporter-${bb_exp_version}.linux-amd64.tar.gz

mkdir -p ~/tmp_deb
wget ${bb_ext_get_url} -O ~/tmp_deb/blackbox_exporter-${bb_exp_version}.linux-amd64.tar.gz
mkdir ~/tmp_deb/blackbox_exporter_bin
tar -xvf ~/tmp_deb/blackbox_exporter-${bb_exp_version}.linux-amd64.tar.gz -C ~/tmp_deb/blackbox_exporter_bin/
mv tmp_deb/blackbox_exporter_bin/blackbox_exporter-${bb_exp_version}.linux-amd64/blackbox_exporter /usr/local/bin/
rm -rfv ~/tmp_deb
useradd -rs /bin/false blackbox-exp

cat <<EOF > /etc/systemd/system/blackbox_exporter.service
[Unit]
Description=prometheus blackbox_exporter
After=network-online.target
Wants=network-online.target

[Service]
User=blackbox-exp
Group=blackbox-exp
ExecStart=/usr/local/bin/blackbox_exporter \
    --web.listen-address=${used_ip}:${bb_exp_port} \
    --config.file="/etc/blackbox-exporter.yml"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/blackbox-exporter.yml
modules:
  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: ip4
      source_ip_address: ${icmp_target_ip}
EOF

systemctl daemon-reload
systemctl enable --now blackbox_exporter
systemctl status blackbox_exporter