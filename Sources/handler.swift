//
//  handler.swift
//  PerfectTemplate
//
//  Created by 止水 on 12/15/16.
//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectWebSockets
import Foundation

class AccessLayerHandler: WebSocketSessionHandler {
 
	let socketProtocol: String? = nil
	
	static let sharedInstance = AccessLayerHandler()
	
	private init() {}
 
	// This function is called by the WebSocketHandler once the connection has been established.
	func handleSession(request: HTTPRequest, socket: WebSocket) {

		/// 给 socket 添加消息响应函数
		socket.onMessageHandler = {
			message, op, fin in
			guard let string = message else {
				/// 对方挂起
				socket.close()
				PublishCenter.sharedInstance.publish(socket: socket, message: ["topic": "App.End.Log", "session_id":"*"])
				return
			}
			if let data = (string as? String)?.data(using: .utf8) {
				guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
				
				if let publish = json?["publish"] {
					PublishCenter.sharedInstance.publish(socket: socket, message: publish as! [String: Any])
				}
				
				if let subscribe = json?["subscribe"] {
					SubscribeCenter.sharedInstance.subscribe(socket: socket, message: subscribe as! [String: Any])
				}
				
				if let unsubscribe = json?["unsubscribe"] {
					SubscribeCenter.sharedInstance.unsubscribe(socket: socket, message: unsubscribe as! [String:Any])
				}
			}
		}
	}
}
