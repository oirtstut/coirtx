# Create a service file for persistent coirtx-agent2

## Create /etc/systemd/system/coirtx-agent2.service

/etc/systemd/system/coirtx-agent2.service

```

[Unit]
Description=Coirtx Agent2
After=network.target

[Service]
Type=simple
User=coirtx
Group=coirtx

ExecStart=/opt/coirtx/sbin/zabbix_agent2 \
    -c /etc/coirtx/zabbix_agent2.conf

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

```

Reload systemd

```

sudo systemctl daemon-reload

```

Enable and start service

```

sudo systemctl enable --now coirtx-agent2

```

Verify and check status

```

systemctl status coirtx-agent2 --no-pager

ss -ltnp | grep 10050

pgrep -fa zabbix_agent2

```

