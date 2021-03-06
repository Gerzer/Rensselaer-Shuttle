//
//  RensselaerShuttleApp.swift
//  Rensselaer Shuttle
//
//  Created by Gabriel Jacoby-Cooper on 9/11/20.
//

import SwiftUI

@main struct RensselaerShuttleApp: App {
	
	var body: some Scene {
		WindowGroup {
			self.contentView
		}
			.commands {
				CommandGroup(before: .sidebar) {
					Button("Refresh") {
						self.contentView.refreshBuses()
					}
						.keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
				}
			}
	}
	
	private var contentView = ContentView()
	
}
