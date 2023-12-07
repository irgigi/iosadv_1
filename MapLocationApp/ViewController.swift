//
//  ViewController.swift
//  MapLocationApp

import CoreLocation
import MapKit
import UIKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    let locManager = CLLocationManager()
    let geocoder = CLGeocoder()
    let myCoordinate = CLLocationCoordinate2D(latitude: 57.92149, longitude: 59.98162)
    
    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.isZoomEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        map.addGestureRecognizer(tapGesture)
        return map
    }()
    
    //для приблизить
    lazy var zoomInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .lightGray.withAlphaComponent(0.5)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        return button
    }()
    
    //для отдалить
    lazy var zoomOutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .lightGray.withAlphaComponent(0.5)
        button.setImage(UIImage(systemName: "minus"), for: .normal)
        button.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        return button
    }()
    
    //для чистки меток и polyline
    lazy var clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "clear"), for: .normal)
        button.addTarget(self, action: #selector(removaAllAnnotations), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        view.addSubview(mapView)
        view.addSubview(zoomInButton)
        view.addSubview(zoomOutButton)
        view.addSubview(clearButton)
        setup()
        mapView.delegate = self
        //checkLocationPermission()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        //locManager.startUpdatingLocation()
        addAnotation(myCoordinate)
        setupSearchButton()
    
    }
    
    //поиск городва
    func setupSearchButton() {
        let searchButton = UIBarButtonItem(title: "Search", style: .plain, target: self, action: #selector(searchButtonTapped))
        navigationItem.rightBarButtonItem = searchButton
    }
    
    @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let tapPoint = gestureRecognizer.location(in: mapView)
            let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            let tapRoundCoordinate = CLLocationCoordinate2D(latitude: round(100000 * tapCoordinate.latitude) / 100000, longitude: round(100000 * tapCoordinate.longitude) / 100000)
            print("---", tapRoundCoordinate)
            
            let fixedCoordinate = myCoordinate
            print("---", fixedCoordinate)
            getDirections(sourceCoordinate: fixedCoordinate, destinationCoordinate: tapRoundCoordinate)
            /*
            if let userLocation = locManager.location?.coordinate {
                getDirections(sourceCoordinate: userLocation, destinationCoordinate: tapCoordinate)
            }
             */
        }
    }
    
    @objc func searchButtonTapped() {
        showCityInputAlert()
    }
    
    @objc func zoomIn() {
        var region = mapView.region
        region.span.latitudeDelta *= 0.5
        region.span.longitudeDelta *= 0.5
        mapView.setRegion(region, animated: true)
    }
    
    @objc func zoomOut() {
        var region = mapView.region
        region.span.latitudeDelta *= 1.5
        region.span.longitudeDelta *= 1.5
        mapView.setRegion(region, animated: true)
    }
    //очистить всё
    @objc func removaAllAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    //MARK: -delegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline  else { return MKOverlayRenderer() }
        let render = MKPolylineRenderer(polyline: polyline)
        render.strokeColor = .blue
        render.lineWidth = 5
        return render

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "CustomAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }

    //MARK: -other methods
    
    func getDirections(sourceCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.coordinate = sourceCoordinate
        sourceAnnotation.title = "Start"
        mapView.addAnnotation(sourceAnnotation)
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destinationCoordinate
        destinationAnnotation.title = "Finish"
        mapView.addAnnotation(destinationAnnotation)
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        

        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        directionsRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionsRequest)
        
        directions.calculate { (responce, error) in
            if let error = error {
                print("getting", error)
            }
            
            guard let responce = responce else { return }
            let route = responce.routes[0]
            
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func showCityInputAlert() {
        let alertController = UIAlertController(title: "Enter city", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "City"

        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let searchAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            if let city = alertController.textFields?.first?.text {
                self?.geocodeCity(city)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(searchAction)
        
        
        present(alertController, animated: true)
    }
    
    func addAnotation(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        let coordinate2D = coordinate
        annotation.coordinate = coordinate2D
        annotation.title = "I live here"
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: coordinate2D, latitudinalMeters: 100000, longitudinalMeters: 100000)
        mapView.setRegion(region, animated: true)
        
    }
    
    
    func checkLocationPermission() {
        
        if locManager.authorizationStatus == .notDetermined {
            locManager.requestWhenInUseAuthorization()
        }
        
        if locManager.authorizationStatus == .denied {
            //отправить пользователя в настройки
        }
        if locManager.authorizationStatus == .authorizedWhenInUse {
            locManager.startUpdatingLocation()
        }
    }
    
    func geocodeCity(_ city: String) {
        geocoder.geocodeAddressString(city) { (placemark, error) in
            if let error = error {
                print(error)
            } else if let place = placemark?.first {
                self.showLocationOnMap(place)
            }
        }
    }
    
    func showLocationOnMap(_ placemark: CLPlacemark) {
        if let location = placemark.location {
            let coordinate = location.coordinate
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100000, longitudinalMeters: 100000)
            mapView.setRegion(region, animated: true)
            //mapView.removeAnnotations(mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func setup() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        zoomInButton.translatesAutoresizingMaskIntoConstraints = false
        zoomOutButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            zoomInButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            zoomInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            zoomOutButton.topAnchor.constraint(equalTo: zoomInButton.bottomAnchor, constant: 10),
            zoomOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            clearButton.topAnchor.constraint(equalTo: zoomOutButton.bottomAnchor, constant: 10),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        
        ])
    }


}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coordinate = location.coordinate
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
    
        let coordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        mapView.centerCoordinate = coordinate2D
        
        mapView.setCenter(coordinate2D, animated: true)
        let region = MKCoordinateRegion(center: coordinate2D, latitudinalMeters: 1000000, longitudinalMeters: 1000000)
        mapView.setRegion(region, animated: true)
    }
}

