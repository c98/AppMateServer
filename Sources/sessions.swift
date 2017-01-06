//
//  sessions.swift
//  PerfectTemplate
//
//  Created by 止水 on 1/3/17.
//
//

import Foundation
import PerfectWebSockets

/// 会话管理模块
class Session: ModuleProtocol {
	
	enum DBError: Error {
		case CreateOutputStreamFailed
		case CreateInputStreamFailed
	}
	
	struct SessionElement {
		var session_id: String
		var device_name: String
		var did: String
		var app_name: String
		var app_version: String
		var platform: String
		var os_version: String
		var connect_time: String
		var connect_status: Int
		var socket: WebSocket?
	}
	
	var sessions: [SessionElement] = []
	var active_session_count: Int = 0
	var hearbeat_ack_sessions: [String] = []
	var timer: DispatchSourceTimer? = nil
	var checkTimer: DispatchSourceTimer? = nil
	
	func sessionsInfo() -> [[String:Any]] {
		return self.sessions.map { [
				"session_id": $0.session_id,
				"device_name": $0.device_name,
				"did": $0.did,
				"app_name": $0.app_name,
				"app_version": $0.app_version,
				"platform": $0.platform,
				"os_version": $0.os_version,
				"connect_time": $0.connect_time,
				"connect_status": $0.connect_status
			] }
	}
	
	init() {
		try? self.loadSessions()
		self.heartBeat()
	}
	
	func loadSessions() throws {
		guard let input = InputStream.init(fileAtPath: "./sessions.json") else {
			throw DBError.CreateInputStreamFailed
		}
		input.open()
		guard let sessions = try? JSONSerialization.jsonObject(with: input, options: []) as? [[String:Any]] else {
			return
		}
		
		for session in sessions! {
			guard let session_id = session["session_id"] as? String else { return }
			guard let device_name = session["device_name"] as? String else { return }
			guard let did = session["did"] as? String else { return }
			guard let app_name = session["app_name"] as? String else { return }
			guard let app_version = session["app_version"] as? String else { return }
			guard let platform = session["platform"] as? String else { return }
			guard let os_version = session["os_version"] as? String else { return }
			guard let connect_time = session["connect_time"] as? String else { return }
			let connect_status = 0
			let sessionElement = SessionElement.init(session_id: session_id,
			                                         device_name: device_name,
			                                         did: did,
			                                         app_name: app_name,
			                                         app_version: app_version,
			                                         platform: platform,
			                                         os_version: os_version,
			                                         connect_time: connect_time,
			                                         connect_status: connect_status,
			                                         socket: nil)
			self.sessions.append(sessionElement)
		}
	}
	
	func saveSessions() throws {
		self.syncSessionCount()
		
		if self.sessions.count == 0 {
			return
		}
		
		var index = 0
		for i in (0..<self.sessions.count).reversed() {
			let session = self.sessions[i]
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			
			if let date = dateFormatter.date(from: session.connect_time) {
				if Date().timeIntervalSince(date) <= 1000*60*60*24*3 {
					index = i
					break
				}
			}
		}
		
		self.sessions = Array(self.sessions.prefix(through: index))

		guard let output = OutputStream.init(toFileAtPath: "./sessions.json", append: false) else {
			throw DBError.CreateOutputStreamFailed
		}
		output.open()
		JSONSerialization.writeJSONObject(self.sessionsInfo(), to: output, options: [JSONSerialization.WritingOptions.prettyPrinted], error: nil)
		
		let msg: [String:Any] = ["topic":"session.list",
		           "session_id":"*:*:*",
		           "payload":self.sessionsInfo()]
		SubscribeCenter.sharedInstance.notify(message: msg)
	}
	
	func syncSessionCount() {
		var active_session_count = 0
		for session in self.sessions {
			if session.connect_status == 1 {
				active_session_count += 1
			}
		}
		self.active_session_count = active_session_count
	}
	
	
	func heartBeat() {
		self.timer = DispatchSource.makeTimerSource()
		self.timer?.scheduleRepeating(deadline: DispatchTime.now(), interval: 10)
		self.timer?.resume()
		self.timer?.setEventHandler {
			self.hearbeat_ack_sessions = []
			for session in self.sessions {
				if session.connect_status == 0 {
					continue
				}
				
				let msg = [
					"publish":[
						"topic":"HeartBeat.SYN",
						"session_id":session.session_id
					]
				]
				guard let content = String.init(data: try! JSONSerialization.data(withJSONObject: msg), encoding: String.Encoding.utf8) else {
					assert(false)
					break
				}
				session.socket!.sendStringMessage(string: content, final: true) {}
			}
			
			self.checkTimer = DispatchSource.makeTimerSource()
			self.checkTimer?.scheduleOneshot(deadline: DispatchTime.now() + .seconds(5))
			self.checkTimer?.resume()
			self.checkTimer?.setEventHandler {
				var index = 0
				while index < self.sessions.count {
					var session = self.sessions[index]
					if session.connect_status == 0 {
						index += 1
						continue
					}
					
					if self.hearbeat_ack_sessions.index(of: session.session_id) != nil {
						if session.connect_status != 1 {
							session.connect_status = 1
							self.sessions.remove(at: index)
							self.sessions.insert(session, at: 0)
						}
					} else {
						if session.connect_status != 2 {
							session.connect_status = 2
							self.sessions.insert(session, at: self.active_session_count)
							self.sessions.remove(at: index)
						}
					}
					
					self.syncSessionCount()
					
					index += 1
				}
				try? self.saveSessions()
			}
		}
	}
	
	func onHeartBeat_ACK(socket:WebSocket, topic:String, sessionId:String, message:[String:Any]) {
		self.hearbeat_ack_sessions.append(sessionId)
	}
	
	func handleEvent(socket: WebSocket, action: String, topic: String,
	                 sessionId: String, message: [String : Any]) {
		switch action {
		case "publish":
			self.onPublish(socket: socket, topic: topic, sessionId: sessionId, message: message)
			
		case "subscribe":
			self.onSubscribe(socket: socket, topic: topic, sessionId: sessionId, message: message)
			
		default:
			break
		}
	}
	
	func onPublish(socket: WebSocket, topic: String, sessionId: String, message: [String:Any]) {
		switch topic {
		case "App.Start.Log":
			self.onConnect(socket: socket, topic: topic, sessionId: sessionId, message: message)
			
		case "App.End.Log":
			self.onDisconnect(socket: socket, topic: topic, sessionId: sessionId, message: message)
			
		case "HeartBeat.ACK":
			self.onHeartBeat_ACK(socket: socket, topic: topic, sessionId: sessionId, message: message)
			
		default:
			break
		}
	}
	
	func onSubscribe(socket: WebSocket, topic: String, sessionId: String, message: [String:Any]) {
		if topic != "session.list" {
			return
		}
		
		let msg = ["publish": [
				"topic":topic,
				"session_id": sessionId,
				"payload": self.sessionsInfo()
			]]
		guard let content = String.init(data: try! JSONSerialization.data(withJSONObject: msg), encoding: String.Encoding.utf8) else {
			return
		}
		socket.sendStringMessage(string: content, final: true) {}
	}
	
	func onConnect(socket: WebSocket, topic: String, sessionId: String, message: [String:Any]) {
		guard let payload = message["payload"] as? [String:Any] else { return }
		guard let deviceName = payload["deviceName"] as? String else { return }
		guard let platform = payload["platform"] as? String else { return }
		guard let osVersion = payload["osVersion"] as? String else { return }
		let connectTime = format_date()
		
		var isExisted = false
		for (index, var session) in self.sessions.enumerated() {
			if session.session_id == sessionId {
				session.connect_time = connectTime
				session.connect_status = 1
				session.socket = socket
				session.device_name = deviceName
				
				isExisted = true
				self.sessions.remove(at: index)
				self.sessions.insert(session, at: 0)
				
				self.hearbeat_ack_sessions.append(sessionId)
				
				break
			}
		}
		
		if !isExisted {
			let sessionIdComps = sessionId.characters.split(separator: ":").map(String.init)
			let did = sessionIdComps[0]
			let appName = sessionIdComps[1]
			let appVersion = sessionIdComps[2]
			self.sessions.append(SessionElement(session_id: sessionId,
			                                    device_name: deviceName,
			                                    did: did,
			                                    app_name: appName,
			                                    app_version: appVersion,
			                                    platform: platform,
			                                    os_version: osVersion,
			                                    connect_time: connectTime,
			                                    connect_status: 1,
			                                    socket: socket))
		}
		
		try? self.saveSessions()
	}
	
	func onDisconnect(socket: WebSocket, topic: String, sessionId: String, message: [String:Any]) {

		SubscribeCenter.sharedInstance.unsubscribeAll(socket: socket)

		var not_found = true
		for (index, var session) in self.sessions.enumerated() {
			if let sock = session.socket, sock == socket {
				if session.connect_status == 1 {
					session.connect_status = 0
					self.sessions.insert(session, at: self.active_session_count)
					self.sessions.remove(at: index)
				}
				not_found = false
				break
			}
		}
		
		if not_found {
			return
		}
		
		try? self.saveSessions()
	}
}
