AppMateServer

从仓库的名字可以知道，这是 [AppMate](http://s17.mogucdn.com/new1/v1/fxihe/d0da31c875767324becb9e575f68fd34/A1c0b9eca4d2000802.appmate.png) 的服务端。

它是一个基于 Websocket 的简易通讯服务器，编写语言为 `swift`。工程的 master 分支可在 **Xcode 8.2** 及以上编译，当前只能工作在 macOS(10.12+) 平台。

### 前置说明
AppMate 其实是我们小组内部的一个尝试，正式服务的 server 端是用 Nodejs 实现的。用 swift 重写这个项目的核心框架主要是想确认下知名 swift web 框架 [Perfect](https://github.com/PerfectlySoft/Perfect) 的使用手感和稳定性到底如何。另外也想知道使用 swift 可以做到什么程度。

关于平台兼容性，这确实是一个问题。因为 [Swift Foundation](https://github.com/apple/swift-corelibs-foundation) 目前还处于早期阶段，[一些模块](https://github.com/apple/swift-corelibs-foundation/blob/master/Docs/Status.md)还没有做到完全跨平台，不幸的是在这个项目中会使用到其中的个别模块(e.g. `Stream`,`DateFormatter`)。另外用到了改版后的 [GCD](https://github.com/apple/swift-corelibs-libdispatch)，当前只能工作在 macOS(10.12+) 平台。

## 编译运行

首先是 clone 工程，SPM 安装依赖
```
git clone https://github.com/c98/AppMateServer.git
cd AppMateServer
swift package fetch
swift package generate-xcodeproj
open *.xcodeproj
```
缺省的服务端端口是 8011，你可以在 main.swift 中修改。

在 Xcode 中运行服务端，你会看到如下输出：
```
Starting HTTP server on 0.0.0.0:8011 with document root ./webroot
```
这表示服务端已启动，正等待监听，剩下就是手机端 [AppMateClient](https://github.com/c98/AppMateClient) 和浏览器端 [AppMateBrowser](https://github.com/c98/AppMateBrowser) 的访问了。

## 文件组织
server 端主要依赖了 Perfect 框架，项目的源码文件在 Sources 目录下。

```
main.swift: 服务端配置，router handler 设定，主运行循环
handler.swift: 配置 websocket 的 message handler
pubsub.swift: 基于 Publish/Subscribe 的一套简单的通讯模式
plugins.swift: 插件管理，负责注册模块的订阅关系
sessions.swift: 核心插件，负责管理 websocket 应用级会话，包括连接进来、断开、心跳控制等
Test.swift: 一个测试插件，用来订阅手机端发来的 log，进行信息重组再推送给浏览器端
```

## 服务端通讯架构图
![server_arch](http://s17.mogucdn.com/new1/v1/fxihe/1f80350d24a6d62d90e8b4a4d5cae1b0/A16053bca4d2000802.server_arch.png)
