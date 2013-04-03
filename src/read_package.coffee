# https://github.com/cranic/node-tar.gz
targz = require 'tar.gz'
semver = require 'semver'
fs = require 'fs'

checkGzipFormat = ( path , cb ) ->
    buffer = new Buffer(2)
    fs.open path , 'r' , ( err , fd ) ->
        if err then return cb(err)
        fs.fstat fd , ( err , stats ) ->
            if err then return cb(err)
            if stats.size < 2 then return cb("incorrect gzip header check.")
            fs.read fd , buffer , 0 , buffer.length , null , (err,bytesRead,buffer) ->
                fs.close(fd)
                if buffer[0] is 0x1f and buffer[1] is 0x8b 
                    cb( null )
                else
                    cb("incorrect gzip header check.")

###
 callback ( err , pkgconfig , tmpfile ) 
###
readPackage = ( path , callback ) ->
    
    dir = "#{path}_extract/"
    conf_path = "#{dir}fekit.config"

    checkGzipFormat path , (err) ->

        if err then return callback(err)
        
        new targz().extract path , dir , ( err ) ->

            if !fs.existsSync(conf_path) then return callback("'fekit.config' file not found in package.")
            
            conf_str = fs.readFileSync(conf_path).toString()
            
            try
                json = JSON.parse(conf_str)

                if !json.name 
                    return callback("'fekit.config' hasn't name field.")

                if !json.version 
                    return callback("'fekit.config' hasn't version field.")

                if !semver.valid( json.version )
                    return callback("'fekit.config' version invalid.")

                callback( null , json , path )
            catch err
                return callback("'fekit.config' is invalid json string.")


module.exports = readPackage