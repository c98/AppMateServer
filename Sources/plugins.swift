//
//  plugins.swift
//  PerfectTemplate
//
//  Created by 止水 on 1/3/17.
//
//

import Foundation


class PluginManager {
	
	static var sharedInstance = PluginManager()
	
	private init() {}
	
	func loadPlugins() {
		let sessions = Session()
		PublishCenter.sharedInstance.register(topic: "App.Start.Log", module: sessions)
		PublishCenter.sharedInstance.register(topic: "App.End.Log", module: sessions)
		PublishCenter.sharedInstance.register(topic: "session.list", module: sessions)
		PublishCenter.sharedInstance.register(topic: "HeartBeat.ACK", module: sessions)
		
		PublishCenter.sharedInstance.register(topic: "*.Log", module: Test())
		
	}
}
