#!/bin/bash

path=$(cd $(dirname $0);echo $PWD)
cd $path
sudo pm2 stop fekit-package-server
sudo pm2 start $path/start.js --name="fekit-package-server"