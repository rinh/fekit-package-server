#!/bin/bash
path=$(cd $(dirname $0);echo $PWD)

[[ -e $path/pid.nohup ]] && kill -QUIT `cat $path/pid.nohup`
sleep 2
cd $path
nohup sudo node $path/node_modules/.bin/coffee $path/src/cli.coffee >/dev/null 2>&1 &
echo $! > $path/pid.nohup
