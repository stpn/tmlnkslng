#!/bin/bash
sudo /etc/init.d/redis-server stop &
wait
sudo /etc/init.d/nginx restart &
wait
god terminate &
wait
god -c config/resque-production.god &
wait
sudo /etc/init.d/redis-server start
