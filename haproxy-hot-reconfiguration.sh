#!/bin/bash
#A hot reconfiguration script would look like this :
#Extract from http://haproxy.1wt.eu/download/1.3/doc/architecture.txt

# save previous state
mv /etc/haproxy/config /etc/haproxy/config.old
mv /var/run/haproxy.pid /var/run/haproxy.pid.old

mv /etc/haproxy/config.new /etc/haproxy/config
kill -TTOU $(cat /var/run/haproxy.pid.old)
if haproxy -p /var/run/haproxy.pid -f /etc/haproxy/config; then
    echo "New instance successfully loaded, stopping previous one."
    kill -USR1 $(cat /var/run/haproxy.pid.old)
    rm -f /var/run/haproxy.pid.old
    exit 1
else
    echo "New instance failed to start, resuming previous one."
    kill -TTIN $(cat /var/run/haproxy.pid.old)
    rm -f /var/run/haproxy.pid
    mv /var/run/haproxy.pid.old /var/run/haproxy.pid
    mv /etc/haproxy/config /etc/haproxy/config.new
    mv /etc/haproxy/config.old /etc/haproxy/config
    exit 0
fi