//
//  OfficeSettingsView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import MapKit

struct OfficeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var locationManager: LocationManager
    var notificationManager: NotificationManager
    
    @State private var position: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var radius: Double
    @State private var isShowingSearch = false
    
    init(locationManager: LocationManager, notificationManager: NotificationManager) {
        self.locationManager = locationManager
        self.notificationManager = notificationManager
        let initialCoord = CLLocationCoordinate2D(
            latitude: locationManager.officeLatitude,
            longitude: locationManager.officeLongitude
        )
        _selectedCoordinate = State(initialValue: initialCoord)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoord,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
        _radius = State(initialValue: locationManager.allowedRadius)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Instruction Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set Office Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Drag the map to center the red dot on your office building.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Map View
                    ZStack {
                        Map(position: $position) {
                            UserAnnotation()
                            
                            // Visual representation of the allowed radius
                            MapCircle(center: selectedCoordinate, radius: radius)
                                .foregroundStyle(.blue.opacity(0.3))
                                .stroke(.blue, lineWidth: 2)
                        }
                        .mapStyle(.standard(emphasis: .muted))
                        .onMapCameraChange { context in
                            selectedCoordinate = context.region.center
                        }
                        
                        // Center Crosshair/Marker
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                                .shadow(radius: 3)
                            
                            Spacer().frame(height: 20) // Account for pin point
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()
                    
                    // Settings Panel
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Detection Radius")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(Int(radius)) meters")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                            
                            Slider(value: $radius, in: 50...500, step: 10)
                                .tint(.blue)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                        
                        Button {
                            locationManager.updateOfficeLocation(
                                latitude: selectedCoordinate.latitude,
                                longitude: selectedCoordinate.longitude,
                                radius: radius
                            )
                            notificationManager.sendLocationSavedNotification()
                            dismiss()
                        } label: {
                            Text("Save Office Location")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let userLocation = locationManager.currentLocation {
                            withAnimation {
                                position = .region(MKCoordinateRegion(
                                    center: userLocation.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                ))
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
