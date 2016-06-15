var coffee = require('coffee-script');
coffee.register()

var server = require( __dirname + "/src/app.coffee" )
server.startApp()