//
//  GpsViewController.swift
//  Project Beach Titan
//
//  Created by Mark Eaton on 7/18/16.
//  Copyright © 2016 Mark Eaton. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class GpsViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate  {

    var locationManager: CLLocationManager!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var button_CenterOnUser: UIButton!
    
    let regionRadius: CLLocationDistance = 100
    var initialMapLoaded = false

    //MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatButtons()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        
        self.mapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .Default
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
    //MARK:  Core Location
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if (status == .AuthorizedAlways || status == .AuthorizedWhenInUse) {
            locationManager.startUpdatingLocation()
            
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.mapView.showsUserLocation = true
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager Error!")
    }
    
    func centerMapOnLocation(location: CLLocation?) {
        
        if let value = location {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(value.coordinate, regionRadius * 2.0, regionRadius * 2.0)
            mapView.setRegion(coordinateRegion, animated: true)
        } else {
            return
        }
    }
    
    //MARK: Mapkit 
    
    @IBAction func centerMapOnUser(sender: AnyObject) {
        centerMapOnLocation(locationManager.location)
        print(locationManager.location?.description)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if initialMapLoaded == false {
            initialMapLoaded = true
            centerMapOnLocation(userLocation.location)
        }
    }

    //MARK: UI Updates
    
    func formatButtons() {
        
        let cornerRadius: CGFloat = 10.0
        
        button_CenterOnUser.layer.masksToBounds = true
        button_CenterOnUser.layer.cornerRadius = cornerRadius

    }
    
}
