//
//  BlockButton.swift
//  Rensselaer Shuttle
//
//  Created by Gabriel Jacoby-Cooper on 9/22/20.
//ß

import SwiftUI

struct BlockButtonStyle: ButtonStyle {
	
	@State var color = Color.accentColor
	
	struct BlockButton: View {
		
		let configuration: BlockButtonStyle.Configuration
		
		@Environment(\.isEnabled) var isEnabled
		@State var color: Color
		
		var body: some View {
			self.configuration.label
				.frame(maxWidth: .infinity)
				.background(self.isEnabled ? self.color : Color.gray)
				.foregroundColor(.white)
				.opacity(self.configuration.isPressed ? 0.5 : 1)
				.cornerRadius(10)
		}
		
	}
	
	func makeBody(configuration: Configuration) -> some View {
		BlockButton(configuration: configuration, color: self.color)
	}
	
}

struct BlockButtonPreviews: PreviewProvider {
	
	static var previews: some View {
		Button(action: self.handleButton) {
			Text("Do Something")
				.padding(10)
		}
			.buttonStyle(BlockButtonStyle())
			.padding()
	}
	
	static func handleButton() { }
	
}
