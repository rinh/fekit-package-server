_ = require 'underscore'
path = require 'path'
fs = require 'fs'
nano = require('nano')('http://127.0.0.1:5984')
semver = require 'semver'

exports.test = false

get_db_name = () ->
    if exports.test then "registry_testcase" else "registry"

initdb = ( cb ) ->
    nano.db.create get_db_name() , ( err , body ) ->
        db = nano.db.use get_db_name()
        cb( null , db )

exports.clearDB = ( cb ) ->
    nano.db.destroy get_db_name() , ( err ) ->
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

    over = original['dist-tags']['latest']
    ver = config.version

    if over and semver.gt( over , ver ) or semver.eq( over , ver )
        throw "提交版本大于或等于当前版本."
    else 
        original['dist-tags']['latest'] = ver
        if !original.versions then original.versions = {}
        original.versions[ver] = config

    return original


exports.delete_model = delete_model = ( original , pkgname , version ) ->

    throw "没有找到 #{pkgname}, 请确认是否发布到源中。" if !original

    throw "没有找到 #{pkgname}@#{version} " if !original.versions[version]

    delete original.versions[version]

    vers = _.keys( original.versions ) 

    return null if vers.length is 0 

    high_ver = semver.maxSatisfying( vers )

    throw "找不到最高版本" if !high_ver

    original['dist-tags']['latest'] = high_ver

    return original


exports.find = find = ( name , cb ) ->

    initdb (err,db) ->

        if err then return cb(err)

        db.get name , { revs_info : true } , ( err , body ) ->

            #if err and err.status_code is 404 then return cb( null , null )
            if err and err.status_code is 200 then return cb( null , body )
            cb( err , body )


exports.find_tar = find_tar = ( name , tarfilename , cb ) ->

    initdb ( err , db ) ->

        if err then return cb(err)

        db.attachment.get name , tarfilename , cb


exports.save = save = ( config , zipfilepath , cb ) ->

    _id = config.name
    _ver = config.version

    initdb (err, db) ->

        if err then return cb(err)        

        find _id , ( err , body ) ->

            if err and err.status_code isnt 404 then return cb(err)

            try 
                model = update_model( body , config ) 
            catch err 
                return cb( err )

            db.insert model , _id , ( err , saved_body ) ->

                if err then return cb(err)

                filename = "#{config.name}-#{config.version}.tgz"

                fs.readFile zipfilepath , ( err , data ) ->

                    if err then return cb(err)

                    db.attachment.insert _id , filename , data , 'application/octet-stream' , { rev : saved_body.rev } , ( err , doc ) ->

                        cb( err , doc )


exports.delete = deleteEntity = ( pkgname , version , cb ) ->

    _id = pkgname 

    initdb (err, db) ->

        if err then return cb(err)

        find _id , ( err , body ) ->

            if err and err.status_code isnt 404 then return cb(err)
            if err and err.status_code is 404 then return cb("没有找到 #{pkgname}, 请确认是否发布到源中。")

            try 
                if version 
                    model = delete_model( body , pkgname , version ) 
                else 
                    model = null
            catch err 
                return cb( err )

            if model 

                db.insert model , _id , ( err , deleted_body ) ->

                    if err then return cb(err)

                    filename = "#{_id}-#{version}.tgz"

                    db.attachment.destroy _id , filename , deleted_body.rev , ( err , doc ) ->

                        cb( err , doc )

            else 

                db.destroy _id , body._rev , ( err , doc ) ->

                    cb( err , doc ) 


