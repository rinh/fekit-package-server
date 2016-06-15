_ = require 'underscore'
path = require 'path'
fs = require 'fs'
config = require '../config.json'
nano = require('nano')('http://' + config.database_host + ':5984')
semver = require 'semver'

exports.test = false

exports.get = ( dbname ) ->

    m = require("./db/#{dbname}")

    m.dbname = if exports.test then "#{dbname}_testcase" else dbname

    m.clearDB = ( cb ) ->
        nano.db.destroy m.dbname , ( err ) ->
            cb()

    return m
