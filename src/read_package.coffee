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
    readme_path = "#{dir}README.md"

    checkGzipFormat path , (err) ->

        if err then return callback(err)
        
        new targz().extract path , dir , ( err ) ->

            if !fs.existsSync(conf_path) then return callback("'fekit.config' file not found in package.")
            
            conf_str = fs.readFileSync(conf_path).toString()
            
            try
                json = JSON.parse(conf_str)

                if !json.name 
                    return callback("'fekit.config' 没有 name 字段.")

                if !json.version 
                    return callback("'fekit.config' 没有 version 字段.")

                if !semver.valid( json.version )
                    return callback("'fekit.config' version 不正确.")

                if !json.author
                    return callback("'fekit.config' 没有 author 字段.")

                if !json.email
                    return callback("'fekit.config' 没有 email 字段.")

                if !json.description
                    return callback("'fekit.config' 没有 description 字段.")

                unless fs.existsSync( readme_path )
                    return callback("请在发布内容中包含 README.md 文件")

                callback( null , json , path )
            catch err
                return callback("'fekit.config' 不是正确的 json 格式.")


module.exports = readPackage