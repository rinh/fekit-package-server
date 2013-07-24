md5 = require 'md5'
_ = require 'underscore'
syspath = require 'path'
fs = require 'fs'
nano = require('nano')('http://127.0.0.1:5984')

exports.dbname = "user"


get_db_name = () ->
    return exports.dbname 
    
initdb = ( cb ) ->
    nano.db.create get_db_name() , ( err , body ) ->
        db = nano.db.use get_db_name()
        cb( db )

exports.add = ( name , password , cb ) ->
    initdb ( db ) ->
        find name , ( err , body ) ->
            if body then return cb("已经存在 #{name} 用户")
            u = 
                name : name , 
                password_md5 : md5.digest_s( password ) , 
                create_time : new Date()

            db.insert u , name , ( err , saved_body ) ->
                cb( err , u , saved_body )


exports.login = ( name , password , cb ) ->
    initdb ( db ) ->
        find name , ( err , body ) ->
            if !body then return cb( "用户名不正确" ) 
            if body.password_md5 is md5.digest_s( password ) 
                cb null , body 
            else
                cb "密码不正确"


exports.login_private_key = ( name , private_key , cb ) ->
    initdb ( db ) ->
        find name , ( err , body ) ->
            if !body then return cb( "用户名不正确" ) 
            if body.password_md5 is private_key
                cb null , body 
            else
                cb "密钥不正确"


exports.changePwd = ( name , oripwd , newpwd , cb ) ->
    initdb ( db ) ->
        find name , ( err , body ) ->
            if err then return cb( err ) 
            if body.password_md5 isnt md5.digest_s( oripwd ) then return cb('原密码不正确.')
            body.password_md5 = md5.digest_s( newpwd ) 
            db.insert body , name , ( err , saved_body ) ->
                cb( err , body , saved_body ) 


exports.find = find = ( name , cb ) ->
    initdb (db) ->
        db.get name , { revs_info : true } , ( err , body ) ->
            if err and err.status_code is 200 then return cb( null , body )
            cb( err , body )
