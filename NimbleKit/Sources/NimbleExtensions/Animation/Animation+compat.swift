//
//  Animation+compat.swift
//  NimbleKit
//

import SwiftUI

extension Animation {
	/// iOS 17 `.snappy` is not available on iOS 16.1.x and crashes FetchRequest updates.
	public static var compatSnappy: Animation {
		if #available(iOS 17.0, *) {
			return .snappy
		} else {
			return .easeInOut(duration: 0.25)
		}
	}
	
	/// iOS 17 `.smooth` is not available on iOS 16.1.x.
	public static var compatSmooth: Animation {
		if #available(iOS 17.0, *) {
			return .smooth
		} else {
			return .easeInOut
		}
	}
}
