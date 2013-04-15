fekit package server
====================

## 简介 ##

fekit 可以发布、安装、删除包。 
包是一组程序的集合，一般是组件或独立应用。任何一个标准的 fekit 项目均可以成为包。

## how to install  ##
    
    install CouchDB
    git clone https://github.com/rinh/fekit-package-server
    cd fekit-package-server
    npm install

## how to run

    npm start

## how to test ##

    npm test


## fekit.config

要成为一个包，在 fekit 项目内应包括 fekit.config 文件，它是用来安装及发布的依据。

    {
         "name" : "包名称" , 
         "author" : "rinh" , 
         "email" : "rinh@abc.com" , 
         //指定某个文件作为包入口, 该路径以src目录为根.  默认使用 src/index  
         "main" : "home" ,                   
         "version" : "1.2.3" , //遵循semver
         "dependencies" : {
               "dialog" : "1.2.*"    
         } , 
         "description" : "" , 
         "scripts" : {}
    }

## 版本号管理

包的版本号分为 版本号.子版本号.修订版本号

## 相关命令

### fekit install
根据 fekit.config 安装全部依赖包

### fekit install [module name[@version]]
指定某个特定包进行安装

》 安装的包统一放在 fekit.config 同级目录 fekit_modules 目录中
》 安装流程：

1. check 本地 fekit_modules 是否已经存在该模块, 如果存在则不进行安装
2. check 指定安装包的依赖 [http] , 如果找不到某个依赖（或版本）则返回失败
3. 递归查找所有子依赖，并形成依赖树。重复第2步操作。如果任一子依赖找不到（或版本）[http] 则返回失败
4. 依赖树确认后成功后，下载安装。 
  4.1 先删除旧有版本
  4.2 下载时根据依赖树建立目录并安装

使用非指定式安装，则循环当前项目 dependencies 即可
 

### fekit uninstall [module name]

卸载已经安装的包
删除放在 fekit_modules 中的指定包
 
### fekit publish 
发布包，将当前 fekit 项目发布至源服务器

源服务器

提供包管理的基础环境

数据库

使用 couchdb 进行管理

数据库表为 registry , 结构（以datepicker为例）为

    {
         _id : "datepicker" , 
         _rev : "60-xxxxxxxxxxx" , 
         _attachments : {                   
              "datepicker-0.0.2.tgz" ,
              "datepicker-0.0.1.tgz" 
         } ,
         name : "datepicker" , 
         description : "this is a datepicker" ,
         author : {
              "name" : "hao.lin" , 
              "email" : "hao.lin@qunar.com" 
         } , 
         dist-tags : {
              "lasest" : "0.0.2" 
         } ,
         versions : {
              "0.0.1" : { object ( 0.0.1 版本的 fekit.config ) } , 
              "0.0.2" : { object ( 0.0.2 版本的 fekit.config ) } , 
         }
    }



## API

### GET /packagename
根据名称查询包

    {
        "name": "foo",  
        "dist-tags": { 
            "latest": "0.1.2" , 
            "tar ball":"http://domain.com/0.1.tgz" 
        },  
        "versions": {    
            "0.1.2": {      
                "name": "foo",      
                "version": "0.1.2",      
                "dist": { 
                    "tarball": "http:\/\/domain.com\/0.1.tgz"
                },      
                "description": "A fake package",      
                "config": { /* fekit.config 配置 */ }    
            }  
        },  
        "description": "A fake package."
    }



### GET /packagename/0.1.2
根据名称及版本号指定查询


    {
        "name": "foo",   
        "version": "0.1.2",   
        "dist": { 
            "tarball": "http:\/\/domain.com\/0.1.tgz" 
        },   
        "description": "A fake package",   
        "config": { 
            /* fekit.config 配置 */ 
        }
    }



### GET /packagename/latest
根据名称及版本号指定查询

    {
        "name": "foo",   
        "version": "0.1.2",   
        "dist": { 
            "tarball": "http:\/\/domain.com\/0.1.tgz" 
        },   
        "description": "A fake package"，    
        "config": { /* fekit.config 配置 */ }
    }


### GET /packagename/-/tarname-version.tgz
指定版本号的包进行上传并入库

### PUT /packagename
指定版本号的包进行上传并入库

提交需要包含 fekit 项目标准 tar 包(已gzip)

    {
         "ret" : false
         "errmsg" : ""
    }

