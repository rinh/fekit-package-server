temp = require 'temp'
async = require 'async'
path = require 'path'
fs = require 'fs'
request = require 'request'
dblib = require "../src/db"
app = require "../src/app"
assert = require('chai').assert

dblib.test = true
db = dblib.get('registry')
userdb = dblib.get('user')

PORT = 3300

GET_TEST_FILE = ( name ) ->
    path.join path.dirname(__filename) , 'app' , name

DELETE = ( path , opts , cb ) ->
    opts.url = "http://127.0.0.1:#{PORT}#{path}"
    opts.method = 'DELETE'
    request opts , cb

GETS = ( path , opts , cb ) ->
    opts.url = "http://127.0.0.1:#{PORT}#{path}"
    request opts , cb

GET = ( path , cb ) ->
    request.get "http://127.0.0.1:#{PORT}#{path}" , ( err , res , body ) ->
        cb JSON.parse(body)

PUT_FILE = ( path , file , cb ) ->
    fs.createReadStream( file ).pipe( 
        request
            uri: "http://127.0.0.1:#{PORT}#{path}"
            method: "PUT"
            multipart: ['content-type' : 'application/octet-stream']
        , ( err , res , body ) ->
            cb JSON.parse(body)
    )

PUT = ( path , body , cb ) ->
    request.put "http://127.0.0.1:#{PORT}#{path}" , {
            form : body 
        }, ( err , res , body ) ->
            cb err , res , body

app.startApp(PORT,{
        test : true
    })

describe 'app' , ->

    before ( done ) ->
        db.clearDB done

    it '#get /:pkgname should be missing.' , ( done ) ->

        GET '/datepicker' , ( json ) ->
            assert.equal json.ret , false
            done()

    after ( done ) ->
        db.clearDB done


describe 'app' , ->

    before ( done ) ->
        db.clearDB done

    it '#put /:pkgname' , ( done ) ->

        PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.1.tgz') , ( body ) ->
            assert.ok body.ret
            db.find 'datepicker' , (err, json) ->
                done()

    it '#put /:pkgname second' , ( done ) ->

        PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.2.tgz') , ( body ) ->
            assert.ok body.ret
            db.find 'datepicker' , (err, json) ->
                done()

    after ( done ) ->
        db.clearDB done


describe 'app' , ->

    before ( done ) ->
        a = ( ok ) ->
            db.clearDB ok
        b = ( ok ) ->
            PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.1.tgz') , () ->
                ok()
        c = ( ok ) ->
            PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.2.tgz') , () ->
                ok()
        async.series [a,b,c] , () ->
            done()


    it '#get /:pkgname/latest' , ( done ) ->

        GET '/datepicker/latest' , ( body ) ->
            assert.equal body.ret , true
            assert.equal body.data.version , '0.0.2'
            done()


    it '#get /:pkgname/0.0.1' , ( done ) ->

        GET '/datepicker/0.0.1' , ( body ) ->
            assert.equal body.ret , true
            assert.equal body.data.version , '0.0.1'
            done()


    it '#get /:pkgname' , ( done ) ->

        GET '/datepicker' , ( body ) ->
            assert.equal body.ret , true
            assert.equal body.data['dist-tags']['latest'] , '0.0.2'
            done()


    after ( done ) ->
        db.clearDB done



describe 'app' , ->

    before ( done ) ->
        a = ( ok ) ->
            db.clearDB ok
        b = ( ok ) ->
            PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.1.tgz') , () ->
                ok()
        c = ( ok ) ->
            PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.2.tgz') , () ->
                ok()
        async.series [a,b,c] , () ->
            done()


    it '#get /:pkgname/-/:tarname' , ( done ) ->
        GETS '/datepicker/-/xxxxx' , {} , ( err , res , body ) ->
            assert.equal res.statusCode , 404
            done()

    it '#get /:pkgname/-/:tarname' , ( done ) ->

        p = temp.path()
        stream = fs.createWriteStream( p )
 
        GETS '/datepicker/-/datepicker-0.0.2.tgz' , { encoding: null } , ( err , res , body ) ->
            assert.equal res.statusCode , 200
            assert.equal body[0] , 0x1f
            assert.equal body[1] , 0x8b
            done()


    after ( done ) ->
        db.clearDB done



describe 'app' , ->

    before ( done ) ->
        a = ( ok ) ->
            db.clearDB ok
        b = ( ok ) ->
            PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.1.tgz') , () ->
                ok()
        c = ( ok ) ->
            PUT_FILE '/datepicker' , GET_TEST_FILE('datepicker-0.0.2.tgz') , () ->
                ok()
        async.series [a,b,c] , () ->
            done()


    it '#delete /:pkgname/:version' , ( done ) ->
        DELETE '/datepicker/0.0.3' , {} , ( err , res , body ) ->
            assert.equal res.statusCode , 200
            assert.equal JSON.parse(body).ret , false 
            done()

    it '#delete /:pkgname/:version' , ( done ) ->
        DELETE '/datepicker/0.0.2' , {} , ( err , res , body ) ->
            assert.equal res.statusCode , 200
            assert.equal JSON.parse(body).ret , true 
            done()

    after ( done ) ->
        db.clearDB done



describe 'user' , ->

    before ( done ) ->
        userdb.clearDB done

    it '#add' , ( done ) ->
        PUT '/user/signup' , {
            username : 'hao.lin'
            password : '12345'
        } , ( err , res , body ) ->
            body = JSON.parse body
            assert.equal body.ret , true
            assert.equal body.data.name , "hao.lin"
            done()

    it '#add' , ( done ) ->
        PUT '/user/signup' , {
            username : 'hao.lin'
            password : 'aaaaas'
        } , ( err , res , body ) ->
            body = JSON.parse body
            assert.equal body.ret , false
            done()

    it '#signin' , ( done ) ->
        PUT '/user/signin' , {
            username : 'hao.lin' 
            password : '12345'
        } , ( err , res , body ) ->
            body = JSON.parse body
            console.info( body )
            assert.equal body.ret , true 
            assert.equal body.data.name , 'hao.lin'
            done()

    it '#signin' , ( done ) ->
        PUT '/user/signin' , {
            username : 'hao.lin' 
            password : 'xxxxx'
        } , ( err , res , body ) ->
            body = JSON.parse body
            assert.equal body.ret , false
            done()

    it '#changePwd' , ( done ) ->
        PUT '/user/changePwd' , {
            username : 'hao.lin' 
            origin_password : '12345'
            new_password : '67890'
        } , ( err , res , body ) ->
            body = JSON.parse body
            assert.equal body.ret , true
            done()

    it '#signin' , ( done ) ->
        PUT '/user/signin' , {
            username : 'hao.lin' 
            password : '67890'
        } , ( err , res , body ) ->
            body = JSON.parse body
            assert.equal body.ret , true 
            assert.equal body.data.name , 'hao.lin'
            done()

    after ( done ) ->
        userdb.clearDB done



