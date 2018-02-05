// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "PerfectTemplate",
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", from: "3.0.0"),
		.package(url: "https://github.com/c98/Perfect-WebSockets.git", .exact("3.0.0-c98"))
    ],
	targets: [
		.target(name: "app", dependencies:["PerfectHTTPServer", "PerfectCURL", "PerfectWebSockets"], path: "")
	]
)
