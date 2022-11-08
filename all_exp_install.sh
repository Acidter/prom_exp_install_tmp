#!/bin/bash
set -xe

wget https://raw.githubusercontent.com/Acidter/prom_exp_install_tmp/master/node_exporter_install.sh
bash node_exporter_install.sh

wget https://raw.githubusercontent.com/Acidter/prom_exp_install_tmp/master/process_exporter_install.sh
bash process_exporter_install.sh