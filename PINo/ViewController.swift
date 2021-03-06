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
    
    var selectedTitle = ""
    var selectedTitleID: UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()


     
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
        
        if selectedTitle != "" {
            //core data'dan çekme işlemi
            let appDelegate  = UIApplication.shared.delegate as! AppDelegate
            let context  = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)  //filtreleme işlemi
            fetchRequest.returnsObjectsAsFaults=false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0{
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinates = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinates
                                        mapView.addAnnotation(annotation)
                                        locatioNameTxt.text = annotationTitle
                                        commenTxt.text = annotationSubtitle
                                        //lokasyon güncellemelerini durdurur, sadece pinin bulunduğu bölgeye gider
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinates, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
                
            }catch{
                print("error")
            }
        }else{
            //add new data
        }
                                            
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
        if selectedTitle == "" {
        //enlem boylam
        let locations = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom işlemi
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        //belirtilen enlem ve boylamı zoomlayacak harita
        let region = MKCoordinateRegion(center: locations, span: span)
            mapView.setRegion(region, animated: true)
            
        }
        else{
            //seçilen title boş ise saptanan konuma
            //değilse pinlenen konuma gider
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //kullanıcının mevcut konumunu pinle göstermemesi için mevcut konumu nil döndürüyoruz
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "annotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        //pinview'ın oluşturulmadığı durumlarda
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.purple
            
            //pinimize buton ekleme işlemi
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //pinimize eklediğimiz butona yazdığımız fonksiyon
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            let  requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
                        //navigasyonumuzu çalıştırmak için gerekli olan objeleri alabilmemiz için
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in //closure
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        //map item oluşturabilmemiz için ise place mark denilen bir objeye ihtiyacımız var
                       let newPlaceMark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlaceMark) //navigasyonu açabilmemiz için mapitem oluşturmalıyız
                        item.name = self.annotationTitle
                        //oluşturduğumuz mapitem içerisinde hangi modu kullancağımızı belirtiyoruz
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDefault]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
            
        } else {
            
        }
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
        NotificationCenter.default.post(name: NSNotification.Name("new place"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}
    
 


