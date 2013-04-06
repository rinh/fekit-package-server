_ = require 'underscore'

class Entity

    initialize : ( @jsonData , @http_prefix ) ->


    getAllPackage : () ->

        vers = {}

        dist = getLasestPackage()

        for ver of @jsonData.versions
            vers[ver] = @getPackage( ver )

        obj = 
            name: @jsonData.name
            'dist-tags': 
                lasest: dist.version
                tarball: dist.dist.tarball
            versions: vers
            description: @jsonData.description

        return obj

    getLasestPackage : () ->

        return @getPackage( @jsonData['dist-tags']['lasest'] )
    
    getPackage : ( ver ) ->

        obj = 
            name: @jsonData.name
            version: ver
            dist:
                tarball: "#{@http_prefix}#{@jsonData.name}/#{ver}/-/#{@jsonData}-#{ver}.tgz"
            description: @jsonData.description

        return obj


    
module.exports = Entity