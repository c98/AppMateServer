//
//  pubsub.swift
//  PerfectTemplate
//
//  Created by 止水 on 12/26/16.
//
//

import Foundation
import PerfectWebSockets

protocol ModuleProtocol {
	func handleEvent(socket: WebSocket, action: String, topic: String,
	                 sessionId: String, message: [String: Any])
}

/// 因为 ModuleProtocol 并不直接支持比较，这里增加该类型的全局比较操作
func ==(_ lhs: ModuleProtocol, _ rhs: ModuleProtocol) -> Bool {
	let l_p = Unmanaged<AnyObject>.passUnretained(lhs as AnyObject).toOpaque()
	let r_p = Unmanaged<AnyObject>.passUnretained(rhs as AnyObject).toOpaque()
	return l_p == r_p
}

/// 因为 WebSocket 并不直接支持比较，这里增加该类型的全局比较操作
func ==(_ lhs: WebSocket, _ rhs: WebSocket) -> Bool {
	let l_p = Unmanaged<AnyObject>.passUnretained(lhs as AnyObject).toOpaque()
	let r_p = Unmanaged<AnyObject>.passUnretained(rhs as AnyObject).toOpaque()
	return l_p == r_p
}


/// 消息发布中心
class PublishCenter {
	/// topic -> module 映射表
	var topicTable: [String: [ModuleProtocol]]

	static var sharedInstance = PublishCenter()

	private init() {
		topicTable = [String: [ModuleProtocol]]()
	}
	
	/// topic 注册
	func register(topic:String, module:ModuleProtocol) {
		var modules: [ModuleProtocol]? = self.topicTable[topic];
		if modules == nil {
			modules = [ModuleProtocol]();
		}
		
		if (modules?.index(where: { $0 == module })) == nil {
			modules?.append(module)
			self.topicTable[topic] = modules
		}
	}
	
	/// topic 反注册
	func unregister(topic:String, module:ModuleProtocol) {

		guard var modules = self.topicTable[topic] else {
			return
		}
		
		guard let index = modules.index(where: { $0 == module }) else {
			return
		}
		
		modules.remove(at: index)
		self.topicTable[topic] = modules;
	}
	
	/// 消息路由
	func publish(socket: WebSocket, message: [String:Any]) {
		guard let topic = message["topic"] as? String else { return }
		guard let session_id = message["session_id"] as? String else { return }

		event_callback(socket: socket, action: "publish", topic: topic, session_id: session_id, message: message, topic_table: self.topicTable, default_cb: SubscribeCenter.sharedInstance.notify)
	}
}

/// 消息订阅中心
class SubscribeCenter {
	
	typealias EntryType = (topic: String, session_id: String, sockets: [WebSocket])
	
	/// topic -> socket 映射表
	var subscribeTable: [EntryType]
	
	static var sharedInstance = SubscribeCenter()
	
	private init() {
		subscribeTable = [EntryType]()
	}
	
	/// socket 订阅某 topic
	func subscribe(socket: WebSocket, message: [String: Any]) {
		guard let topic = message["topic"] as? String else { return }
		guard let session_id = message["session_id"] as? String else { return }
		
		var new_entry: EntryType? = nil
		var index: Int? = nil
		for (i, entry) in self.subscribeTable.enumerated() {
			if entry.topic == topic
				&& entry.session_id == session_id {
				new_entry = entry
				index = i
				break
			}
		}
		if new_entry == nil {
			new_entry = (topic: topic, session_id: session_id, sockets:[socket])
			self.subscribeTable.append(new_entry!)
		} else if (new_entry!.sockets.index(where: { $0 == socket })) == nil {
			new_entry!.sockets.append(socket)
			self.subscribeTable.remove(at: index!)
			self.subscribeTable.insert(new_entry!, at: index!)
		}
		
		event_callback(socket: socket, action: "subscribe", topic: topic, session_id: session_id, message: message, topic_table: PublishCenter.sharedInstance.topicTable, default_cb: nil)
	}
	
	/// socket 取消订阅某 topic
	func unsubscribe(socket: WebSocket, message: [String: Any]) {
		guard let topic = message["topic"] as? String else { return }
		guard let session_id = message["session_id"] as? String else { return }
		
		for (index, var entry) in self.subscribeTable.enumerated() {
			if entry.topic == topic
				&& entry.session_id == session_id {
				if let i = entry.sockets.index(where: { $0 == socket }) {
					entry.sockets.remove(at: i)
					self.subscribeTable.remove(at: index)
					self.subscribeTable.insert(entry, at: index)
				}
				break
			}
		}
	}
	
	func unsubscribeAll(socket: WebSocket) {
		for (index, var entry) in self.subscribeTable.enumerated() {
			if let i = entry.sockets.index(where: { $0 == socket }) {
				entry.sockets.remove(at: i)
				self.subscribeTable.remove(at: index)
				self.subscribeTable.insert(entry, at: index)
			}
		}
	}
	
	/// 消息广播给订阅的 sockets
	func notify(message: [String: Any]) {
		guard let topic = message["topic"] as? String else { return }
		guard let session_id = message["session_id"] as? String else { return }
		
		var sockets = [WebSocket]()
		for entry in self.subscribeTable {
			if topic_match(topic: topic, pattern: entry.topic)
				&& session_id_match(session_id: session_id, pattern: entry.session_id) {
				sockets.append(contentsOf: entry.sockets)
				break
			}
		}
		
		guard let content = String.init(data: try! JSONSerialization.data(withJSONObject: ["publish":message]), encoding: String.Encoding.utf8) else {
			return
		}
		
		_ = sockets.map {
			$0.sendStringMessage(string: content, final: true) {}
		}
	}
}
