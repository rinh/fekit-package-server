md5 = require 'md5'
_ = require 'underscore'
syspath = require 'path'
fs = require 'fs'
config = require '../../config.json'
nano = require('nano')('http://' + config.database_host + ':5984')

exports.dbname = "star"


get_db_name = () ->
    return exports.dbname 

    
initdb = ( cb ) ->
    nano.db.create get_db_name() , ( err , body ) ->
        is_new_db = !err
        db = nano.db.use get_db_name()
        if is_new_db 
            init_design db , () ->
                cb( null , db )
        else 
            cb( null , db )

init_design = ( db , cb ) ->

    stars_map = (doc) ->
        emit( null , {
                name : doc.name 
                username : doc.username 
                level : doc.level
            })

    _init_design db , 'stars' , stars_map , ( err ) ->
        cb()

_init_design = ( db , id , map_func , cb ) ->

    content = 
        language : 'javascript' 
        views : 
            rows : 
                map : map_func.toString()

    _id = "_design/#{id}"

    find _id , ( err , body ) ->
        if body and boby._rev 
            db.destroy _id , body._rev , ( err , doc ) ->
                db.insert content , _id , cb 
        else 
            db.insert content , _id , cb 

# level 1-5
exports.add = ( name , username , level , cb ) ->
    initdb ( err , db ) ->
        d = {
            key : "#{name}_#{username}"
            name : name 
            username : username 
            level : if isNaN(level) then 0 else parseInt( level , 10 )
        } 

        find d.key , ( err , body ) ->
            if err and err.statusCode is 404 
                db.insert d , d.key , ( err , saved_body ) ->
                    cb( err , d , saved_body )
            else
                cb('已经提交过评级，不能重复提交。')


exports.find = find = ( name , cb ) ->

    initdb (err,db) ->

        if err then return cb(err)

        db.get name , { revs_info : true } , ( err , body ) ->

            #if err and err.statusCode is 404 then return cb( null , null )
            if err and err.statusCode is 200 then return cb( null , body )
            cb( err , body )


exports.list = ( cb ) ->
    initdb ( err , db ) ->
        db.view 'stars' , 'rows' , ( err , body ) ->
            if err then return cb( err , [] )

            group_list = []
            group = {}

            for r in body.rows 
                i = r.value
                unless group[i.name] then group[i.name] = { name : i.name , count : 0 , sum : 0 }
                v = group[i.name]
                v.count++
                v.sum += i.level

            for key , g of group
                g.star = Math.floor( g.sum / g.count )
                group_list.push g 

            cb( err , group_list , group )













