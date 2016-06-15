fs = require 'fs'

{print} = require 'util'
{spawn} = require 'child_process'

process_stdio = (proc,callback) ->
    proc.stderr.pipe process.stderr, end: false 
    proc.stdout.pipe process.stdout, end: false 
    proc.on 'exit', (code) ->
        callback?() if code is 0

build = (option,callback) ->
    coffee = spawn './node_modules/.bin/coffee', option
    process_stdio coffee , callback

test = () ->
    m = [ '--colors', '--recursive', '--compilers', 'coffee:coffee-script/register' , '--timeout' , '50000' ]
    console.info './node_modules/.bin/mocha' , m.join(' ')
    mocha = spawn './node_modules/.bin/mocha' , m
    process_stdio mocha


coffee = "./node_modules/.bin/coffee"

echo = (child) ->
  child.stdout.on "data", (data) -> print data.toString()
  child.stderr.on "data", (data) -> print data.toString()
  child

install = (cb) ->
    console.log "Building..."
    echo child = spawn coffee, ["-c", "-o", "lib", "src"]
    child.on "exit", (status) -> cb?() if status is 0

#-------------------

task 'watch', 'Watch src/ for changes', ->
    build ['-w','-c','-o','lib','src']

task 'build', 'Build lib/ from src/', ->
    build ['-c','-o','lib','src']

task 'test', 'Test all case', ->
    test();

task "install", "Install, build, and test repo", install
