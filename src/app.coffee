fs = require "fs"
temp = require "temp"
request = require "request"
http = require "http"
connect = require "connect"
urlrouter = require "urlrouter"
formidable = require "formidable"
url = require "url"
docs = require "fekit-package-docs"

readPackage = require "./read_package"
db = require "./db"
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
    
    form = new formidable.IncomingForm()

    form.parse req , ( err , fields , files ) ->

        callback( err , files.file.path )


getHttpPrefix = ( req ) ->
    
    "http://#{req.headers['host']}/"


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

                wrap_output( res , list )

        app.get '/search/:keyword' , ( req , res , next ) ->

            db.search req.params.keyword , ( err , list ) ->

                if assert(err,res) then return

                wrap_output( res , list )


        app.put '/:pkgname' , ( req , res , next ) ->

            saveTempfile req , res , ( err , path  ) ->
                if assert(err,res) then return

                readPackage path , ( err , pkgconfig , tmpfile , readmeContent ) ->
                    if assert(err,res) then return

                    pkgconfig.README = readmeContent

                    db.save pkgconfig , tmpfile , ( err ) ->
                        if assert(err,res) then return

                        # 生成 doc 
                        docs.createDoc pkgconfig.name , pkgconfig.version , ( err ) ->

                            if assert(err,res) then return

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

            db.delete req.params.pkgname , req.params.version , ( err , pkg ) ->

                if assert(err,res) then return

                wrap_output( res )


        app.delete '/:pkgname/' , ( req , res , next ) ->

            db.delete req.params.pkgname , null , ( err , pkg ) ->

                if assert(err,res) then return

                wrap_output( res )




    app = connect()
            .use( connect.logger( 'tiny' ) ) 
            .use( approuter )
            .use( connect.bodyParser() ) 
            .use( connect.query()  ) 


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