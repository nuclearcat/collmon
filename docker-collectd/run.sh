#!/bin/sh
if [ ! -f "/etc/collectd/collectd.conf" ]; then
    echo Copy default config
    mkdir -p /etc/collectd
    cp /tmp/collectd.conf /etc/collectd/
    cp /tmp/passwd /etc/collectd/
fi
collectd -C /etc/collectd/collectd.conf -f
