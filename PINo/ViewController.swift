//
//  ViewController.swift
//  PINo
//
//  Created by MEWO on 12.07.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var locatioNameTxt: UITextField!
    @IBOutlet weak var commenTxt: UITextField!
    let locationManager = CLLocationManager()
    
    //seçilen konumun enlem ve boylamını almak için
    var choosenLatitude = Double()
    var choosenLongitude = Double()
     
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //konum keskinliği
        //kullanıcıdan konum izni alma
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
                                            
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began
        {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            choosenLongitude = touchedCoordinates.longitude
            choosenLatitude = touchedCoordinates.latitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = locatioNameTxt.text!
            annotation.subtitle = commenTxt.text!
            mapView.addAnnotation(annotation)
            
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //enlem boylam
        let locations = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom işlemi
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        //belirtilen enlem ve boylamı zoomlayacak harita
        let region = MKCoordinateRegion(center: locations, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(locatioNameTxt.text, forKey: "title")
        newPlace.setValue(commenTxt.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("kaydedildi")
            
        }catch{
            print("error")
        }
        
    }
}

