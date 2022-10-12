#!/bin/bash

echo "new server text, man" > index.html
nohup busybox httpd -f -p ${server_port} &