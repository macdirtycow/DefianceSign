//
//  View+compatContentTransition.swift
//  NimbleKit
//

import SwiftUI

extension View {
	/// `contentTransition` plus `withAnimation` hangs SwiftUI layout on iOS 16.0–16.2.
	@ViewBuilder
	public func compatContentTransition() -> some View {
		if #available(iOS 16.4, *) {
			self.contentTransition(.opacity)
		} else {
			self
		}
	}
	
	@ViewBuilder
	public func compatNumericContentTransition() -> some View {
		if #available(iOS 17.0, *) {
			self.contentTransition(.numericText())
		} else {
			self
		}
	}
}
