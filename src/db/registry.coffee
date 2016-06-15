_ = require 'underscore'
path = require 'path'
fs = require 'fs'
config = require '../../config.json'
nano = require('nano')('http://' + config.database_host + ':5984')
semver = require 'semver'

exports.dbname = "registry"

get_db_name = () ->
    return exports.dbname 
    
initdb = ( cb ) ->
    nano.db.create get_db_name() , ( err , body ) ->
        is_new_db = !err
        db = nano.db.use get_db_name()
        if is_new_db 
            _initdb db , () ->
                cb( null , db )
        else 
            cb( null , db )

_initdb = ( db , cb ) ->
    # 添加 view
    _map = (doc) ->
        emit( null , {
                name : doc.name 
                version : doc['dist-tags']['latest']
                description : doc.description 
                tags : doc.tags || []
                update_time : doc.update_time || new Date(2000,1,1)
            })

    content = 
        language : 'javascript' 
        views : 
            rows : 
                map : _map.toString()

    _id = '_design/packages'

    find _id , ( err , body ) ->
        if body and boby._rev 
            db.destroy _id , body._rev , ( err , doc ) ->
                db.insert content , _id , cb 
        else 
            db.insert content , _id , cb 


exports.init_design = () ->

    initdb (err,db) ->
        _initdb db , ( err ) ->
            console.info('init design done.' + err )


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
            #tags: config.tags || []

    over = original['dist-tags']['latest']
    ver = config.version

    if !!over and semver.gt( over || '0.0.0' , ver ) or semver.eq( over || '0.0.0' , ver )
        throw "提交版本大于或等于当前版本."
    else 
        original['dist-tags']['latest'] = ver
        if !original.versions then original.versions = {}
        # 以下全部使用最新版本的配置节
        original.versions[ver] = config
        original.description = config.description
        #original.tags = config.tags || original.tags || []

    original.update_time = new Date()

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

            #if err and err.statusCode is 404 then return cb( null , null )
            if err and err.statusCode is 200 then return cb( null , body )
            cb( err , body )


exports.update_tags = update_tags = ( name , tags , cb ) ->
    
    _id = name

    initdb ( err,db ) ->

        if err then return cb(err)

        find _id , ( err , body ) ->

            if err and err.statusCode isnt 404 then return cb(err)

            body.tags = tags

            db.insert body , _id , ( err , saved_body ) ->

                cb( err , saved_body )


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

            if err and err.statusCode isnt 404 then return cb(err)

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


exports.delete = deleteEntity = ( pkgname , version , checkAuthFunc , cb ) ->
    
    if checkAuthFunc and !cb 
        cb = checkAuthFunc
        checkAuthFunc = ( done ) ->
            done( null )

    _id = pkgname 

    initdb (err, db) ->

        if err then return cb(err)

        find _id , ( err , body ) ->

            if err and err.statusCode isnt 404 then return cb(err)
            if err and err.statusCode is 404 then return cb("没有找到 #{pkgname}, 请确认是否发布到源中。")

            checkAuthFunc body , ( err ) ->

                if err then return cb( err )

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


exports.search_tag = search_tag = ( tag = '' , cb ) ->

    initdb ( err , db ) ->

        if err then return cb( err )

        db.view 'packages' , 'rows' , ( err , body ) ->

            if err then return cb( err )

            list = ( obj.value for obj in body.rows when ~obj.value.tags.indexOf( tag ) )

            cb( null , list )


exports.search = search = ( keyword = '' , cb ) ->

    initdb ( err , db ) ->

        if err then return cb( err )

        db.view 'packages' , 'rows' , ( err , body ) ->

            if err then return cb( err )

            if keyword
                list = ( obj.value for obj in body.rows when ~obj.id.indexOf(keyword) or ~(obj.value.description || "").indexOf(keyword) )
            else 
                list = ( obj.value for obj in body.rows )

            cb( null , list )
