async = require 'async'
dblib = require("../src/db")
path = require "path"
assert = require('chai').assert

dblib.test = true
db = dblib.get('registry')

mockTar = path.join( path.dirname(__filename) , "db" , "datepicker.tgz" )
mockConfig = ( ver ) ->
    {
         "name" : "datepicker" , 
         "author" : "hao.lin" , 
         "email" : "hao.lin@qunar.com" , 
         "version" : if ver then ver else "0.0.1" ,
         "dependencies" : {} , 
         "description" : "this is a description."
    }

describe '#update_model , check update version' , ->

    it 'empty' , () ->
        m = db.update_model( null , mockConfig() )
        assert.equal m['dist-tags']['latest'] , '0.0.1'
        assert.ok m.versions['0.0.1'] isnt null

    it 'push a greater version' , () ->
        m = () ->
            db.update_model( {
                'dist-tags' : {
                    latest: '0.0.2'
                }
            } , mockConfig() )
        assert.throw m 

    it 'push a lessthan version' , () ->
        m = db.update_model( {
                'dist-tags' : {
                    latest: '0.0.2'
                }
            } , mockConfig('0.0.3') )
        assert.equal m['dist-tags']['latest'] , '0.0.3'
        assert.ok m.versions['0.0.3'] isnt null



describe 'db' , ->

    before ( done ) ->
        db.clearDB done
    
    it '#save() initial should be right.' , (done) ->

        data = mockConfig()
        db.save data , mockTar , ( err , body ) ->
            assert.equal err , null
            assert.ok body.ok 
            done()

    it '#save() second should be right.' , (done) ->

        data = mockConfig('0.0.2')
        db.save data , mockTar , ( err , body ) ->
            assert.equal err , null
            assert.ok body.ok 
            done()

    afterEach ( done ) ->
        db.clearDB done


describe 'db' , ->

    before ( done ) ->

        clr = ( ok ) ->
            db.clearDB ok

        a = ( ok ) ->
            db.save mockConfig('0.0.1') , mockTar , ok

        b = ( ok ) ->
            db.save mockConfig('0.0.2') , mockTar , ok

        async.series [clr,a,b] , () ->
            done()

    it '#find() should be right.' , (done) ->

        db.find 'datepicker' , ( err , item ) ->

            assert.equal err , null
            assert.notEqual item.versions['0.0.1'] , null
            assert.notEqual item.versions['0.0.2'] , null
            assert.notEqual item._attachments['datepicker-0.0.2.tgz'] , null
            assert.notEqual item._attachments['datepicker-0.0.1.tgz'] , null

            done()

    afterEach ( done ) ->
        db.clearDB done


describe 'db' , ->

    before ( done ) ->

        clr = ( ok ) ->
            db.clearDB ok

        a = ( ok ) ->
            db.save mockConfig('0.0.1') , mockTar , ok

        b = ( ok ) ->
            db.save mockConfig('0.0.2') , mockTar , ok

        async.series [clr,a,b] , () ->
            done()

    it '#delete() empty should be right.' , (done) ->

        db.delete 'datepicker' , '0.0.3' , ( err , doc ) ->

            assert.notEqual err , null

            done()

    it '#delete() should be right.' , (done) ->

        db.delete 'datepicker' , '0.0.2' , ( err , doc ) ->
            assert.equal err , null 

            db.delete 'datepicker' , '0.0.1', ( err , doc ) ->  
                assert.equal err , null 
            
                done()


    after ( done ) ->
        db.clearDB done




describe 'db' , ->

    before ( done ) ->

        clr = ( ok ) ->
            db.clearDB ok

        a = ( ok ) ->
            db.save mockConfig('0.0.1') , mockTar , ok

        b = ( ok ) ->
            db.save mockConfig('0.0.2') , mockTar , ok

        async.series [clr,a,b] , () ->
            done()

    it '#search() should be right.' , (done) ->

        db.search 'date' , ( err , list ) ->

            assert.equal err , null

            assert.equal list.length , 1

            assert.equal list[0].name , 'datepicker'

            assert.equal list[0].version , '0.0.2'

            done()

    it '#search() should be right.' , (done) ->

        db.search '' , ( err , list ) ->

            assert.equal err , null

            assert.equal list.length , 1

            done()


    it '#search() should be right.' , (done) ->

        db.search 'xx' , ( err , list ) ->

            assert.equal err , null

            assert.equal list.length , 0

            done()


    after ( done ) ->
        db.clearDB done





