//
//  ContentView.swift
//  Rensselaer Shuttle
//
//  Created by Gabriel Jacoby-Cooper on 9/30/20.
//

import SwiftUI
import MapKit
import Moya

struct ContentView: View {
	
	private enum SheetType: IdentifiableByHashValue {
		
		case board
		
	}
	
	private enum AlertType: IdentifiableByHashValue {
		
		case noNearbyBus
		
	}
	
	private enum StatusText: String {
		
		case mapRefresh = "The map automatically refreshes every 5 seconds."
		case locationData = "You're helping out other users with real-time bus location data."
		case thanks = "Thanks for helping other users with real-time bus location data!"
		
	}
	
	let mapState = MapState()
	let timer = Timer.publish(every: 5, on: .main, in: .common)
		.autoconnect()
	var buttonText: String {
		get {
			switch self.travelState {
			case .notOnBus:
				return "Board Bus"
			case .onWestRoute, .onNorthRoute:
				return "Leave Bus"
			}
		}
	}
	
	@State private var travelState = TravelState.notOnBus
	@State private var statusText = StatusText.mapRefresh
	@State private var sheetType: SheetType?
	@State private var alertType: AlertType?
	@State private var doDisableButton = true
	@State private var busID: Int?
	@State private var locationID: UUID?
	
	var body: some View {
		ZStack {
			self.mapView
				.environmentObject(self.mapState)
				.ignoresSafeArea()
				.onReceive(self.timer) { (_) in
					switch self.travelState {
					case .notOnBus:
						guard let location = LocationUtilities.locationManager.location else {
							break
						}
						let closestBus = self.mapState.buses.min { (firstBus, secondBus) -> Bool in
							let firstBusDistance = firstBus.location.convertForCoreLocation().distance(from: location)
							let secondBusDistance = secondBus.location.convertForCoreLocation().distance(from: location)
							return firstBusDistance < secondBusDistance
						}
						let closestStopDistance = self.mapState.stops.reduce(into: Double.greatestFiniteMagnitude) { (distance, stop) in
							let newDistance = stop.location.distance(from: location)
							if newDistance < distance {
								distance = newDistance
							}
						}
						if closestStopDistance < 10 {
							self.busID = closestBus?.id
							self.locationID = UUID()
						}
					case .onWestRoute, .onNorthRoute:
						if let busID = self.busID, let locationID = self.locationID, let coordinate = LocationUtilities.locationManager.location?.coordinate {
//							let url = URL(string: "https://shuttle.gerzer.software/buses/\(busID)")!
							let location = Bus.Location(id: locationID, date: Date(), coordinate: coordinate.convertToBusCoordinate(), type: .user)
							API.provider.request(.updateBus(busID, location: location)) { (_) in
								return
							}
//							let encoder = JSONEncoder()
//							encoder.dateEncodingStrategy = .iso8601
//							var request = URLRequest(url: url)
//							request.httpMethod = "PATCH"
//							request.httpBody = try! encoder.encode(location)
//							request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//							URLSession.shared.dataTask(with: request).resume()
						}
					}
					self.refreshBuses()
				}
			#if !os(macOS)
			VStack {
				#if !APPCLIP
				Spacer()
				#endif
				HStack {
					Spacer()
					VStack(alignment: .leading) {
						Button {
							switch self.travelState {
							case .notOnBus:
								if self.busID == nil {
									self.alertType = .noNearbyBus
								} else {
									self.sheetType = .board
								}
							case .onWestRoute, .onNorthRoute:
								self.busID = nil
								self.locationID = nil
								self.travelState = .notOnBus
								self.statusText = .thanks
								DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
									self.statusText = .mapRefresh
								}
							}
							self.updateButtonState()
						} label: {
							Text(self.buttonText)
								.padding(10)
						}
							.buttonStyle(BlockButtonStyle())
							.disabled(self.doDisableButton)
						HStack {
							Text(self.statusText.rawValue)
								.layoutPriority(1)
							Spacer()
							self.refreshButton
								.frame(width: 30)
						}
					}
						.padding()
						.background(self.visualEffectView)
						.cornerRadius(20)
					Spacer()
				}
					.padding()
				#if APPCLIP
				Spacer()
				#endif
			}
			#endif
		}
			.sheet(item: self.$sheetType) {
				[Route].download { (routes) in
					DispatchQueue.main.async {
						self.mapState.routes = routes
					}
				}
			} content: { (sheetType) in
				switch sheetType {
				case .board:
					ZStack {
						VStack {
							HStack {
								Spacer()
								Button("Close") {
									self.sheetType = nil
								}
									.padding()
							}
							Spacer()
						}
						VStack {
							Text("Which route did you board?")
							HStack {
								Button {
									self.sheetType = nil
									self.travelState = .onWestRoute
									self.statusText = .locationData
									self.updateButtonState()
								} label: {
									Text("West Route")
										.padding()
								}
									.buttonStyle(BlockButtonStyle(color: .blue))
									.padding(.leading)
								Button {
									self.sheetType = nil
									self.travelState = .onNorthRoute
									self.statusText = .locationData
									self.updateButtonState()
								} label: {
									Text("North Route")
										.padding()
								}
									.buttonStyle(BlockButtonStyle(color: .red))
									.padding(.trailing)
							}
						}
					}
				}
			}
			.alert(item: self.$alertType) { (alertType) -> Alert in
				switch alertType {
				case .noNearbyBus:
					let title = Text("No Nearby Stop")
					let message = Text("You can't board a bus if you're not within ten meters of a stop.")
					let dismissButton = Alert.Button.default(Text("Continue"))
					return Alert(title: title, message: message, dismissButton: dismissButton)
				}
			}
	}
	
	private var refreshButton: some View {
		Button(action: self.refreshBuses) {
			Image(systemName: "arrow.clockwise.circle.fill")
				.resizable()
				.aspectRatio(1, contentMode: .fit)
		}
	}
	
	#if os(macOS)
	private var mapView: some View {
		MapView()
			.toolbar {
				ToolbarItem {
					self.refreshButton
				}
			}
	}
	
	private var visualEffectView: some View {
		VisualEffectView(blendingMode: .withinWindow, material: .hudWindow)
	}
	#else
	private var mapView: some View {
		MapView()
	}
	
	private var visualEffectView: some View {
		VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
	}
	#endif
	
	func refreshBuses() {
		[Bus].download { (buses) in
			DispatchQueue.main.async {
				self.mapState.buses = buses
				self.updateButtonState()
			}
		}
		//		if let location = locationManager.location {
		//			let locationMapPoint = MKMapPoint(location.coordinate)
		//			let nearestStop = self.mapState.stops.min { (firstStop, secondStop) in
		//				let firstStopDistance = MKMapPoint(firstStop.coordinate).distance(to: locationMapPoint)
		//				let secondStopDistance = MKMapPoint(secondStop.coordinate).distance(to: locationMapPoint)
		//				return firstStopDistance < secondStopDistance
		//			}
		//			let busPoints = self.mapState.buses.map { (bus) -> (bus: Bus, mapPoint: MKMapPoint) in
		//
		//			}
		//			self.statusText = "The next bus is \("?") meters away from the nearest stop."
		//		}
	}
	
	func updateButtonState() {
		self.doDisableButton = LocationUtilities.locationManager.location == nil || self.mapState.buses.count == 0 && self.travelState == .notOnBus
	}
	
}
