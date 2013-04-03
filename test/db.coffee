db = require "../src/db"
path = require "path"
assert = require('chai').assert

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
        assert.equal m['dist-tags']['lasest'] , '0.0.1'
        assert.ok m.versions['0.0.1'] isnt null

    it 'push a greater version' , () ->
        m = () ->
            db.update_model( {
                'dist-tags' : {
                    lasest: '0.0.2'
                }
            } , mockConfig() )
        assert.throw m 

    it 'push a lessthan version' , () ->
        m = db.update_model( {
                'dist-tags' : {
                    lasest: '0.0.2'
                }
            } , mockConfig('0.0.3') )
        assert.equal m['dist-tags']['lasest'] , '0.0.3'
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









