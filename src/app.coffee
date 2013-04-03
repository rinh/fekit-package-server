fs = require "fs"
temp = require "temp"
request = require "request"
http = require "http"
connect = require "connect"
urlrouter = require "urlrouter"

readPackage = require "./read_package"
db = require "./db"


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


saveTempfile = ( req , callback ) ->
    data = ''
    res.on 'data' , ( chunk ) ->
        data += chunk
    res.on 'end' , () ->
        temp.open 'fekit-pkg-' , ( err , info ) ->
            if err then return callback(err)
            fs.writeFile info.path , data , 'binary' , (err) ->
                if err then return callback(err)
                callback( info.path , info.fd )


startApp = () ->

    approuter = urlrouter (app) ->

        app.put '/:pkgname' , ( req , res , next ) ->
    
            saveTempfile req , ( err , path , filedesc ) ->
                if assert(err,res) then return
                
                readPackage path , ( err , pkgconfig , tmpfile ) ->
                    if assert(err,res) then return

                        db.save pkgconfig , tmpfile , ( err ) ->
                            if assert(err,res) then return

                            wrap_output( res )

###        

        app.get '/:pkgname' , ( req , res , next ) ->

            db.find_package req.params.pkgname , ( err , pkg ) ->

                if assert(err,res) then return

                wrap_output( res , pkg )



        app.get '/:pkgname/:version' , ( req , res , next ) ->

        app.get '/:pkgname/lasest' , ( req , res , next ) ->

        app.get '/:package/:version/-/:tarname' , ( req , res , next ) ->

        ###


    app = connect()
            .use( connect.logger( 'tiny' ) ) 
            .use( approuter )
            .use( connect.bodyParser() ) 
            .use( connect.query()  ) 


    listenPort( http.createServer(app) , 3300 )


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


startApp()