//
//  Test.swift
//  PerfectTemplate
//
//  Created by 止水 on 1/3/17.
//
//

import Foundation
import PerfectWebSockets

/// 测试模块
/// 订阅 topic 为 *.Log 的消息，并在这里负责处理此类消息
class Test: ModuleProtocol {
	func handleEvent(socket: WebSocket, action: String, topic: String,
	                 sessionId: String, message: [String : Any]) {
		// Consume the message, e.g. save the Log message to db.
		// Here is a example, it refactors the Log, and add `time` field in message payload.
		guard var payload = message["payload"] as? [String:Any] else {
			return
		}
		var content = ""
		for (key, value) in payload {
			content += "\(key):\(value)\n"
		}
		payload["message"] = content
		payload["time"] = format_date()
		var msg = message
		msg["payload"] = payload
		
		SubscribeCenter.sharedInstance.notify(message: msg)
	}
}
