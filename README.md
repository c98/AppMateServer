![AppMate](http://s17.mogucdn.com/new1/v1/fxihe/d0da31c875767324becb9e575f68fd34/A1c0b9eca4d2000802.appmate.png)

## AppMateServer

这是 [AppMate](http://s17.mogucdn.com/new1/v1/fxihe/d0da31c875767324becb9e575f68fd34/A1c0b9eca4d2000802.appmate.png) 的服务端。

它是一个基于 Websocket 的简易通讯服务器，编写语言为 `swift`。工程的 master 分支可在 **Xcode 8.2** 及以上编译，当前只能工作在 macOS(10.12+) 平台。

**See Also**

* [AppMateClient](https://github.com/c98/AppMateClient)
* [AppMateBrowser](https://github.com/c98/AppMateBrowser)

## 前置说明
AppMate 其实是我们小组内部的一个尝试，正式服务的 server 端是用 Nodejs 实现的。用 swift 重写这个项目的核心框架主要是想确认下知名 swift web 框架 [Perfect](https://github.com/PerfectlySoft/Perfect) 的使用手感和稳定性到底如何。其中 websocket 组件是基于官方 [PerfectlySoft/Perfect-WebSockets](https://github.com/PerfectlySoft/Perfect-WebSockets) 自行定制的 Event-Driven 版本，[Pull Request 见此](https://github.com/PerfectlySoft/Perfect-WebSockets/pull/1)。

尝试这个项目另外一点，其实也想知道使用 swift 可以做到什么程度，以及对比其他 server 端(e.g. Nodejs)的优劣势。

最后是关于平台兼容性，这确实是一个问题。因为 [Swift Foundation](https://github.com/apple/swift-corelibs-foundation) 目前还处于早期阶段，[一些模块](https://github.com/apple/swift-corelibs-foundation/blob/master/Docs/Status.md)还没有做到完全跨平台，不幸的是在这个项目中会使用到其中的个别模块(e.g. `Stream`,`DateFormatter`)。另外用到了改版后的 [GCD](https://github.com/apple/swift-corelibs-libdispatch)，当前只能工作在 macOS(10.12+) 平台。

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
![server_arch](http://s17.mogucdn.com/new1/v1/fxihe/3e151b71d90de94c3cf67891406d2193/A10ef391e4d2000802.server_arch.png)


## 后记
AppMate 系列项目是最近一周整理的，踩了一点坑，不过整体而言还算顺利。

如果说有什么想说的，我觉得 server 端会是一个不错的话题。

我大概还算是一名 iOS 开发，虽然近半年基本上不怎么写 iOS 代码了，主要是在搞 Nodejs 后端 和 前端应用。

上文说过我们在内部使用的是 Nodejs 版本，而在这个系列中的 server 端是采用 swift 编写的，这其实是一个偶然也可以说是无奈之举。

我倒是很想尝试在 App 端用 swift 写一点东西，但是因为一些客观条件的限制，目前还无法在生产环境中使用这门语言，转而想用这门语言在一些内部系统的后台中做点事情 ;)

初次使用 swift 编写 server 端应用，碰到了很多问题，给我印象深刻的是 swift 的`值语义`，我以为这个东西很简单，因为这也不是什么新东西，但是在实际编码时忽略了这个简单的概念而处处碰壁。Array 等基础类型是值语义的，尽管语言内部是做了引用语义+COW 优化，由于长期习惯了 `for in` 的引用语义(OC/js)，让我在这个坑里爬了好久。

给我带来一定冲击的是 Optional，虽然从理解上而言不是特别绕，但是真的使用时，发现很多时间都是花在 Optional 上。它强制了我必须认真对待变量为空的可能，
一定程度上提高了编码的可靠性，现在是想偷一点懒都不行，即便只是写一个测试应用。

swift 真的是一个熟悉了才能提高编码效率的语言，初次接触还是比较难受的，好在现在 Xcode 的错误和 autofix 提示都做的非常好了。

同样是开发这个服务端，Nodejs 在开发效率上远超 swift，但是出错率也会高于 swift。有几方面原因，一个是语言本身的严谨度，js 就是太动态了，什么都没有限制，都可以做，这一点真不知道是该让人爱还是恨，swift 天生严谨，限制重重。第二个原因是社区的质量和支持度，以服务端而言，我觉得单从开发体验上，Perfect 离 Node 还有相当距离，尽管 Perfect 目前已经算得上是社区中相对较为完善的 web 框架了。

swift 基础类型比较丰富，如果 Fundation 和其他核心库能完成标准化、跨平台，我觉得作为服务端语言新秀也是相当有吸引力的 ;)
