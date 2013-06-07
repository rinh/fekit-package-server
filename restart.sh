#!/bin/bash

[[ -e ./app.nohup ]] && kill -QUIT `cat ./app.nohup`
sleep 10
nohup sudo npm start >/dev/null 2>&1 &
echo $! > ./app.nohup