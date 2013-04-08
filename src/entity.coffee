_ = require 'underscore'

class Entity

    constructor : ( @jsonData , @http_prefix ) ->

    getAllPackage : () ->

        vers = {}

        dist = @getLatestPackage()

        for ver of @jsonData.versions
            vers[ver] = @getPackage( ver )

        obj = 
            name: @jsonData.name
            'dist-tags': 
                latest: dist.version
                tarball: dist.dist.tarball
            versions: vers
            description: @jsonData.description

        return obj

    getLatestPackage : () ->
        return @getPackage( @jsonData['dist-tags']['latest'] )
    
    getPackage : ( ver ) ->

        obj = 
            name: @jsonData.name
            version: ver
            dist:
                tarball: "#{@http_prefix}#{@jsonData.name}/#{ver}/-/#{@jsonData}-#{ver}.tgz"
            description: @jsonData.description

        return obj


    
exports.Entity = ( data , http_prefix ) ->
    return new Entity( data , http_prefix )