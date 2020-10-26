//
//  ViewController.swift
//  DevApp
//
//  Created by Gleb Skripinsky on 10/24/20.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var weatherDesc: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    let weekdaySymbols  = [
        "Mon", "Tue", "Wen", "Thu", "Fri", "Sat", "Sun"
    ]
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location: CLLocation = manager.location else { return }
        fetchCityAndCountry(from: location) { city, country, error in
            guard let city:String = city, error == nil else { return }
            self.setCurrentWeather(cityString: city);
        }
    }

    func fetchCityAndCountry(from location: CLLocation, completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            completion(placemarks?.first?.locality,
                       placemarks?.first?.country,
                       error)
        }
    }

    func setCurrentWeather(cityString: String) {
        var locationName: String?;
        var locationTime: String?;
        var locationTemperature: Double?;
        

        let weatherURL:String = "http://api.weatherstack.com/current?access_key=ad339cb1ba4d25dc5e77e66604c11821&query=\(cityString.replacingOccurrences(of: " ", with: "%20"))";
        let url = URL(string: weatherURL);
        let task = URLSession.shared.dataTask(with: url!) { (data, response, err) in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : AnyObject];
                if let location = json["location"], let current = json["current"]{
                    locationName = location["name"] as? String;
                    locationTime = location["localtime"] as? String;
                    locationTemperature = current["temperature"] as? Double;
                    let weatherDescription:[String] = current["weather_descriptions"] as! [String];
                    let localTime = locationTime!.components(separatedBy: " ");
                    let dayOfWeek = self.getDayOfWeek(localTime[0]);
                    
                    
                    
                    DispatchQueue.main.async {
                        self.cityLabel.text = "\(locationName!)";
                        self.temperatureLabel.text = "\(locationTemperature!)°"
                        self.timeLabel.text="\(dayOfWeek!), \(localTime[1])"
                        self.weatherDesc.text="\(weatherDescription[0])"
                    }
                }

            } catch let jsonError {
                print (jsonError)
            }

        }
        task.resume();
    }
    
    func getDayOfWeek(_ today:String) -> String? {
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let todayDate = formatter.date(from: today) else { return nil }
        let weekday = weekdaySymbols[Calendar.current.component(.weekday, from: todayDate)-1]
        
        return weekday
    }
}
