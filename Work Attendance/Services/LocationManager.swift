//
//  LocationManager.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import CoreLocation
import Combine
import UserNotifications

@Observable
final class LocationManager: NSObject {
    
    // MARK: - Office Configuration
    
    private let userDefaults = UserDefaults.standard
    private let latKey = "office_latitude"
    private let lonKey = "office_longitude"
    private let radiusKey = "office_radius"
    
    /// Office location coordinates (stored for observation)
    var officeLatitude: Double
    var officeLongitude: Double
    var allowedRadius: CLLocationDistance
    
    func updateOfficeLocation(latitude: Double, longitude: Double, radius: Double? = nil) {
        print("📍 Updating Office Location: \(latitude), \(longitude)")
        officeLatitude = latitude
        officeLongitude = longitude
        userDefaults.set(latitude, forKey: latKey)
        userDefaults.set(longitude, forKey: lonKey)
        
        if let radius = radius {
            allowedRadius = radius
            userDefaults.set(radius, forKey: radiusKey)
        }
    }
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var locationError: String?
    var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }
    
    var isPermissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
    
    // MARK: - Initialization
    
    override init() {
        let savedLat = userDefaults.double(forKey: latKey)
        let savedLon = userDefaults.double(forKey: lonKey)
        let savedRadius = userDefaults.double(forKey: radiusKey)
        
        self.officeLatitude = savedLat == 0 ? 41.311081 : savedLat
        self.officeLongitude = savedLon == 0 ? 69.240562 : savedLon
        self.allowedRadius = savedRadius == 0 ? 200 : savedRadius
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        isLoading = true
        locationError = nil
        
        defer { isLoading = false }
        
        guard isAuthorized else {
            throw LocationError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    func isWithinOfficeArea(location: CLLocation) -> Bool {
        let officeLocation = CLLocation(
            latitude: officeLatitude,
            longitude: officeLongitude
        )
        let distance = location.distance(from: officeLocation)
        return distance <= allowedRadius
    }
    
    func validateOfficeProximity() async throws -> (isValid: Bool, location: CLLocation) {
        let location = try await getCurrentLocation()
        let isValid = isWithinOfficeArea(location: location)
        return (isValid, location)
    }
    
    func distanceFromOffice(location: CLLocation) -> CLLocationDistance {
        let officeLocation = CLLocation(
            latitude: officeLatitude,
            longitude: officeLongitude
        )
        return location.distance(from: officeLocation)
    }


// MARK: - CLLocationManagerDelegate

    func startMonitoringOfficeRegion() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        
        let officeRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: officeLatitude, longitude: officeLongitude),
            radius: allowedRadius,
            identifier: "OfficeRegion"
        )
        officeRegion.notifyOnEntry = true
        officeRegion.notifyOnExit = false // Only notify on entry for now
        
        locationManager.startMonitoring(for: officeRegion)
    }
    
    func stopMonitoringOfficeRegion() {
        for region in locationManager.monitoredRegions {
            if region.identifier == "OfficeRegion" {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            startMonitoringOfficeRegion()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "OfficeRegion" {
            // Trigger local notification
            let content = UNMutableNotificationContent()
            content.title = "Welcome back!"
            content.body = "You have arrived at the office. Don't forget to check in."
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case notAuthorized
    case outsideOfficeArea
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access is required to check in"
        case .outsideOfficeArea:
            return "You must be within the office area to check in"
        case .locationUnavailable:
            return "Unable to determine your location"
        }
    }
}
