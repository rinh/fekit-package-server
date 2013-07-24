md5 = require 'md5'
assert = require('chai').assert

dblib = require("../src/db")
dblib.test = true
db = dblib.get('user')


describe 'user#add' , ->

    before ( done ) ->
        db.clearDB done

    it 'should be right.' , ( done )->
        db.add 'hao.lin', 'abcd' , ( err , body ) ->
            assert.equal body.password_md5 , md5.digest_s('abcd')
            done()

    it 'exists user , should be fail.' , ( done )->
        db.add 'hao.lin', 'abcd' , ( err , body ) ->
            assert.notEqual err , null
            done()

    after ( done ) ->
        db.clearDB done