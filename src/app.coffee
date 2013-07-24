fs = require "fs"
temp = require "temp"
request = require "request"
http = require "http"
connect = require "connect"
urlrouter = require "urlrouter"
formidable = require "formidable"
url = require "url"
qs = require "querystring"
docs = require "fekit-package-docs"

readPackage = require "./read_package"
db = require("./db").get("registry")
userdb = require("./db").get("user")
stardb = require("./db").get("star")
Entity = require("./entity").Entity


wrap_output = ( res , json ) ->
    res.end JSON.stringify({
            ret : true , 
            errmsg : "" , 
            data : if json then json else {}
        })

assert = ( err , res ) ->
    if err 
        res.end JSON.stringify({
                ret : false ,
                errmsg : err.toString()
            })
        return true
    return false


saveTempfile = ( req , res , callback ) ->
    
    if !req.files or !req.files.file then return callback "需要提交组件包"

    callback( null , req.files.file.path )


getHttpPrefix = ( req ) ->
    
    "http://#{req.headers['host']}/"


merge_star = ( list , cb ) ->
    stardb.list ( err , group_list , group ) ->
        for i in list 
            if group[i.name]
                i.star = group[i.name]
            else
                i.star = { count : 0 , star : 0 , sum : 0 }
        cb()

# 用来检查是否可以删除，如果不行，done 要返回 err
checkDeleteFunc = ( req ) ->
    return ( model , done ) ->
        unless req.body then return done('需要登录后才能进行删除操作，发布失败')
        if !req.body.username or !req.body.password_md5 then return done('需要登录后才能进行删除操作，发布失败')
        unless ~model.author.name.indexOf( req.body.username ) then return done("登录帐号(#{req.body.username})与组件作者(#{model.author.name})不一致，删除失败")
        done null


###
    options.test 是否开启测试
###
startApp = ( port , options ) ->

    db.test = options && options.test

    port = port || 3300

    approuter = urlrouter (app) ->

        app.get '/hello' , ( req , res , next ) ->

            res.end('hello , fekit package server.')

        app.get '/search/' , ( req , res , next ) ->

            db.search null , ( err , list ) ->

                if assert(err,res) then return

                merge_star list , () ->
                    
                    wrap_output( res , list )

        app.get '/search/:keyword' , ( req , res , next ) ->

            db.search req.params.keyword , ( err , list ) ->

                if assert(err,res) then return

                merge_star list , () ->
                    
                    wrap_output( res , list )

        app.get '/search_tag/:keyword' , ( req , res , next ) ->

            db.search_tag req.params.keyword , ( err , list ) ->

                if assert(err,res) then return

                merge_star list , () ->
                    
                    wrap_output( res , list )


        app.get '/update_tags/:name' , ( req , res , next ) ->

            _url = url.parse( req.url )
            params = qs.parse( _url.query )

            tags = if params.tags then params.tags.split(",") else []

            db.update_tags req.params.name , tags , ( err , doc ) ->

                if assert(err,res) then return

                wrap_output( res , doc )


        app.put '/:pkgname' , ( req , res , next ) ->

            saveTempfile req , res , ( err , path  ) ->
                if assert(err,res) then return

                readPackage path , ( err , pkgconfig , tmpfile , readmeContent ) ->
                    if assert(err,res) then return

                    pkgconfig.README = readmeContent

                    # req中应该包含 ( req.body.username , req.body.password_md5 )

                    unless req.body then return assert('需要登录后才能进行发布操作，发布失败',res)
                    if !req.body.username or !req.body.password_md5 then return assert('需要登录后才能进行发布操作，发布失败',res)
                    unless ~pkgconfig.author.indexOf( req.body.username ) then return assert("登录帐号(#{req.body.username})与组件作者(#{pkgconfig.author})不一致，发布失败",res)

                    db.save pkgconfig , tmpfile , ( err ) ->

                        if assert(err,res) then return

                        # 生成 doc ，默认位置
                        #docs.createDoc pkgconfig.name , pkgconfig.version , ( err ) ->
                        #    if assert(err,res) then return

                        wrap_output( res )


        app.get '/:pkgname/latest' , ( req , res , next ) ->

            db.find req.params.pkgname , ( err , pkg ) ->

                if assert(err,res) then return

                err = if !pkg then "not found #{req.params.pkgname} package." else null

                if assert(err,res) then return

                wrap_output( res , Entity( pkg , getHttpPrefix(req) ).getLatestPackage() )


        app.get '/:pkgname/-/:tarname' , ( req , res , next ) ->

            db.find_tar req.params.pkgname , req.params.tarname , ( err , data ) ->

                if err 
                    res.writeHead 404
                    res.end()
                    return

                res.writeHead 200 , 
                    'Content-Type' : 'text/plain'
                    
                res.write data
                res.end()



        app.get '/:pkgname/:version' , ( req , res , next ) ->

            db.find req.params.pkgname , ( err , pkg ) ->

                if assert(err,res) then return

                err = if !pkg then "not found #{req.params.pkgname} package." else null

                if assert(err,res) then return

                wrap_output( res , new Entity( pkg , getHttpPrefix(req) ).getPackage( req.params.version ) )


        app.get '/:pkgname' , ( req , res , next ) ->

            db.find req.params.pkgname , ( err , pkg ) ->

                if assert(err,res) then return

                err = if !pkg then "not found #{req.params.pkgname} package." else null

                if assert(err,res) then return

                wrap_output( res , new Entity( pkg , getHttpPrefix(req) ).getAllPackage() )


        app.delete '/:pkgname/:version' , ( req , res , next ) ->

            db.delete req.params.pkgname , req.params.version , checkDeleteFunc( req ) , ( err , pkg ) ->

                if assert(err,res) then return

                wrap_output( res )


        app.delete '/:pkgname/' , ( req , res , next ) ->

            db.delete req.params.pkgname , null , checkDeleteFunc( req ) , ( err , pkg ) ->

                if assert(err,res) then return

                wrap_output( res )


        app.get '/createdoc/:pkgname/:version' , ( req , res , next ) ->

            docs.createDoc req.params.pkgname , req.params.version , req.query.doctype , ( err ) ->

                if assert(err,res) then return

                wrap_output( res )

        # -------- user ---------

        app.put '/user/signup' , ( req , res , next ) ->

            userdb.add req.body.username , req.body.password , ( err , user , saved_body ) ->

                if assert( err , res ) then return 

                wrap_output( res , user ) 


        app.put '/user/signin' , ( req , res , next ) ->

            userdb.login req.body.username , req.body.password , ( err , user , saved_body ) ->

                if assert( err , res ) then return 

                wrap_output( res , user ) 


        app.put '/user/login_private_key' , ( req , res , next ) ->

            userdb.login_private_key req.body.username , req.body.password , ( err , user , saved_body ) ->

                if assert( err , res ) then return 

                wrap_output( res , user ) 


        app.put '/user/changePwd' , ( req , res , next ) ->

            userdb.changePwd req.body.username , req.body.origin_password , req.body.new_password , ( err , user , saved_body ) ->

                if assert( err , res ) then return 

                wrap_output( res , user ) 

        app.put '/user/find' , ( req , res , next ) ->

            userdb.changePwd req.body.username , ( err , user ) ->

                if assert( err , res ) then return 

                wrap_output( res , user ) 

        # -------- star ---------

        app.put '/star/add' , ( req , res , next ) ->

            if !req.body.name then return assert("必须确定组件名",res)
            if !req.body.username then return assert("必须登录才能进行投票",res)
            if !req.body.level then return assert("必须选择一个星级",res)

            stardb.add req.body.name , req.body.username , req.body.level , ( err , star ) ->

                if assert( err , res ) then return 

                wrap_output( res , star ) 


        app.get '/star/find/:name' , ( req , res , next ) ->

            stardb.list ( err , group_list , group ) ->

                if assert( err , res ) then return 

                wrap_output res , group[req.params.name]         


        app.get '/star/list' , ( req , res , next ) ->

            stardb.list ( err , group_list , group ) ->

                if assert( err , res ) then return 

                wrap_output res , 
                        group_list : group_list , 
                        group : group



    app = connect()
            .use( connect.logger( 'tiny' ) ) 
            .use( connect.query()  ) 
            .use( connect.bodyParser() ) 
            .use( approuter )
            


    listenPort( http.createServer(app) , port )


#-----------------


listenPort = ( server, port ) ->
    # TODO 貌似不能捕获error, 直接抛出异常
    server.on "error", (e) ->
        if e.code is 'EADDRINUSE' then console.log "[ERROR]: 端口 #{port} 已经被占用, 请关闭占用该端口的程序或者使用其它端口."
        if e.code is 'EACCES' then console.log "[ERROR]: 权限不足, 请使用sudo执行."
        process.exit 1

    server.on "listening", (e) ->
        console.log "[LOG]: fekit package server 运行成功, 端口为 #{port}."
        console.log "[LOG]: 按 Ctrl + C 结束进程." 

    server.listen( port )

exports.startApp = startApp