#!/bin/bash
ps -A -o pid,command | grep [r]esque-#{Resque::Version}
god terminate
god -c config/resque-production.god