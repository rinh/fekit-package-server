path = require 'path'
fs = require 'fs'
nano = require('nano')('http://127.0.0.1:5984')
semver = require 'semver'

initdb = ( cb ) ->
    nano.db.create 'registry' , ( err , body ) ->
        db = nano.db.use 'registry'
        cb( null , db )

exports.clearDB = ( cb ) ->
    nano.db.destroy 'registry' , ( err ) ->
        cb()


exports.update_model = update_model = ( original , config ) ->
    
    if !original
        original = 
            name: config.name
            description: config.description
            author:
                name: config.author
                email: config.email
            'dist-tags': {}
            versions: {}

    over = original['dist-tags']['lasest']
    ver = config.version

    if over and semver.gt( over , ver ) or semver.eq( over , ver )
        throw "提交版本大于或等于当前版本."
    else 
        original['dist-tags']['lasest'] = ver
        if !original.versions then original.versions = {}
        original.versions[ver] = config

    return original


exports.find = find = ( name , cb ) ->

    initdb (err,db) ->

        if err then return cb(err)

        db.get name , { revs_info : true } , ( err , body ) ->

            if err and err.status_code is 404 then return cb( null , null )
            if err and err.status_code is 200 then return cb( 200 , body )
            cb( err , body )


exports.find_package = find_package = ( name , cb ) ->



exports.save = save = ( config , zipfilepath , cb ) ->

    _id = config.name
    _ver = config.version

    initdb (err, db) ->

        if err then return cb(err)        

        find _id , ( err , body ) ->

            if err then return cb(err)

            try 
                model = update_model( body , config ) 
            catch err 
                return cb( err )

            db.insert model , _id , ( err , saved_body ) ->

                if err then return cb(err)

                filename = path.basename( zipfilepath ).replace('.tgz', "-#{_ver}.tgz") 

                fs.readFile zipfilepath , ( err , data ) ->

                    if err then return cb(err)

                    db.attachment.insert _id , filename , data , 'application/octet-stream' , { rev : saved_body.rev } , ( err , doc ) ->

                        cb( err , doc )

