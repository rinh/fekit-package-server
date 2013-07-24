assert = require('chai').assert

dblib = require("../src/db")
dblib.test = true
db = dblib.get('star')



describe 'star#add' , ->

    before ( done ) ->
        db.clearDB done

    it 'should be right.' , ( done )->
        db.add 'jquery', 'hao.lin', 3 , ( err , body ) ->
            assert.equal err , null

            db.add 'jclass', 'hao.lin', 3 , ( err , body ) ->
                assert.equal err , null

                db.add 'jquery', 'li.wang', 3 , ( err , body ) ->
                    assert.equal err , null
                    
                    done()

    it 'exists user , should be fail.' , ( done )->
        db.add 'jquery', 'hao.lin', 3 , ( err , body ) ->
            assert.notEqual err , null
            done()

    after ( done ) ->
        db.clearDB done


describe 'star#list' , ->

    before ( done ) ->
        db.clearDB () ->
            db.add 'jquery', 'hao.lin', 2 , ( err , body ) ->
                assert.equal err , null
                db.add 'jquery', 'li.wang', 4 , ( err , body ) ->
                    assert.equal err , null
                    done()


    it 'should be right.' , ( done )->

        db.list ( err , group_list , group ) ->
            assert.equal group['jquery'].star , 3
            done()

    after ( done ) ->
        db.clearDB done


