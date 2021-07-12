//
//  ViewController.swift
//  PINo
//
//  Created by MEWO on 12.07.2021.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //konum keskinliği
        locationManager.requestWhenInUseAuthorization() //uygulama kullanırken konum servislerinin kullanılması için izin alıyoruz
        locationManager.startUpdatingLocation() //izin verildiğini varsayarak lokasyon güncellemesini başlatıyoruz
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began
            {
                let touchedPoint = gestureRecognizer.location(in: self.mapView)
                let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotation.title = "Şu Anda Buradasınız"
                annotation.subtitle = "Kava Coffee"
            self.mapView.addAnnotation(annotation)
                
            }
    }
    //kullanıcının konumunu aldıktan sonra ne yapacağımızı yazmak için didUpdateLocations fonksiyonunu kullanıyoruz
    //güncellenen lokasyonları bi dizi içerisinde veriyor
    //CLLocation objesi içinde enlem ve boylam bulunduran bir obje
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //bunu haritada gösterebilmek için bi zoom seviyesi gerekecek
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //ne kadar küçük olursa o kadar zoomlamış oluyoruz
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }

}

