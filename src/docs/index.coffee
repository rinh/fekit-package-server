exec = require('child_process').exec
syspath = require 'path'
findit = require 'findit'
tar = require 'tar'
zlib = require 'zlib'
fs = require 'fs'
fstream = require 'fstream'
temp = require 'temp'
db = require("../db").get("registry")
next = if typeof setImmediate isnt 'undefined' then setImmediate else process.nextTick

exports.output = '/tmp/fekit-package-docs/'

untar = ( data , dest , cb ) ->
    
    _tmp = temp.path()

    fs.writeFileSync _tmp , data 

    fstream.Reader(
                path : _tmp
                type : 'File'
            ).pipe(zlib.createGunzip()).pipe(tar.Extract({path: dest})).on 'end', ->
                cb()

eachTarSrcFile = ( pkgname , version , cb ) ->

    db.find_tar pkgname , "#{pkgname}-#{version}.tgz" , ( err , data ) ->

        return cb( err ) if err 

        temp.mkdir pkgname + "@" + version , ( err , dirpath ) ->

            untar data , dirpath , ( err ) ->

                cb( err ) if err 

                next () ->
                    cb( null , dirpath )

###
opts:
    src : srcpath
    output : output
    done : () ->
###
create = ( opts ) ->
    
    src = opts.src
    output = opts.output
    cb = opts.done
    type = opts.type

    config = syspath.join( __dirname , "../yuidoc_files/yuidoc_config.json" )

    themedir = syspath.join( __dirname , "../yuidoc_files/theme" )

    if type is 'groc'
        cmd = "sudo groc \"#{src}/src/**/*.js\" -o \"#{output}\" "
    else if type is 'yuidoc'
        cmd = "sudo yuidoc \"#{src}/src/\" -o \"#{output}\" -c \"#{config}\" --themedir \"#{themedir}\""

    console.info( cmd )

    exec cmd , {
        env : process.env
    } , ( err , stdout , stderr ) ->

        console.info(" doc created done. ")

        return cb( err ) if err 
        return cb( err ) if stderr

        cb( null )


exports.createDoc = createDoc = ( pkgname , version , type , cb ) ->
    
    eachTarSrcFile pkgname , version , ( err , path ) ->

        return cb( err ) if err

        _dir = syspath.join( exports.output , pkgname , version )

        create 
            src : path
            output : _dir
            type : if type then type else 'groc'
            done : ( err ) ->

                return cb( err ) if err 

                files = findit.sync( exports.output )

                for file in files
                    if syspath.extname( file ) is '.html'

                        return cb( null , file ) 

                cb( null , null )
