fs = require 'fs'
path = require 'path'
assert = require('chai').assert
readPackage = require "../src/read_package"

getpath = () ->
    path.join.apply path , [  path.dirname(__filename) , 'read_package' ].concat( Array.prototype.slice.call(arguments) )

open = ( filename , cb ) ->
    fp = getpath filename
    readPackage fp , cb 
    

describe 'test1', ->
    it 'is right tgz', (done) ->
        fp = getpath('test1.tgz')
        open 'test1.tgz' , ( err , config , tempfile ) ->
            assert.equal config.name , "test1"
            done()


describe 'test2', ->
    it 'is invalid json string', (done) ->
        open 'test2.tgz' , ( err , config , tempfile ) ->
            assert.equal err.toString() , "'fekit.config' is invalid json string."
            done()

describe 'test3', ->
    it 'fekit.config not found ', (done) ->
        open 'test3.tgz' , ( err , config , tempfile ) ->
            assert.equal err.toString() , "'fekit.config' file not found in package."
            done()

describe 'test4', ->
    it 'is invalid tgz', (done) ->
        open 'test4.tgz' , ( err , config , tempfile ) ->
            assert.ok err isnt null
            done()