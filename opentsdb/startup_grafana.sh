#!/bin/bash

sudo groupadd grafana
useradd -g grafana -s /sbin/nologin grafana

wget https://dl.grafana.com/oss/release/grafana-6.2.5-1.x86_64.rpm
sudo yum -y localinstall grafana-6.2.5-1.x86_64.rpm
systemctl daemon-reload
systemctl start grafana-server