//
//  utils.swift
//  PerfectTemplate
//
//  Created by 止水 on 1/3/17.
//
//

import Foundation
import PerfectWebSockets

/*
* utils function.
*/

func topic_match(topic: String, pattern: String) -> Bool {
	var pattern = pattern.replacingOccurrences(of: ".", with: "\\.")
	pattern = pattern.replacingOccurrences(of: "*", with: ".*")
	pattern = "^" + pattern + "$"
	
	let pattern_regex = try! NSRegularExpression.init(pattern: pattern)
	let count = pattern_regex.numberOfMatches(in: topic, options: [], range: NSMakeRange(0, topic.unicodeScalars.count))
	
	return count > 0
}

func session_id_match(session_id: String, pattern: String) -> Bool {
	var pattern = pattern.replacingOccurrences(of: ".", with: "\\.")
	pattern = pattern.replacingOccurrences(of: "*", with: ".*")
	pattern = "^" + pattern + "$"
	
	let pattern_regex = try! NSRegularExpression.init(pattern: pattern)
	let count = pattern_regex.numberOfMatches(in: session_id, options: [], range: NSMakeRange(0, session_id.unicodeScalars.count))
	
	return count > 0
}

/**
* event callback
*
* @param default_cb	the callback if no plugin can resolve the event.
*/

func event_callback(socket: WebSocket, action: String, topic: String, session_id:String,
                    message: [String:Any], topic_table:[String:[ModuleProtocol]],
                    default_cb:(([String:Any]) -> Void)?) {
	
	var modules = [ModuleProtocol]();
	topic_table.forEach { (key: String, value: [ModuleProtocol]) in
		var module_list = [ModuleProtocol]()
		if topic_match(topic: topic, pattern: key) {
			if topic_table[key] != nil {
				module_list = topic_table[key]!
			}
			
			modules.append(contentsOf: module_list)
		}
	}
	
	if modules.count == 0 {
		if default_cb != nil {
			default_cb!(message)
		}
		return
	}
	
	_ = modules.map {
		$0.handleEvent(socket: socket, action: action, topic: topic,
		               sessionId: session_id, message: message)
	}
}

func format_date() -> String {
	let dateFormatter = DateFormatter.init()
	dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
	
	return dateFormatter.string(from: Date())
}
