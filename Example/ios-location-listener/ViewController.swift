//
//  ViewController.swift
//  ios-location-listener
//
//  Created by cc51a8303047eb6bf025205b97c4fbcf51205233 on 08/02/2021.
//  Copyright (c) 2021 cc51a8303047eb6bf025205b97c4fbcf51205233. All rights reserved.
//

import Combine
import ios_location_listener
import os.log
import UIKit

class ViewController: UIViewController {
    let logger = Logger(subsystem: "net.kuama.ios-location-listener", category: "kuama")
    var stream: StreamLocation?
    var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func startButton(_: Any) {
        if #available(iOS 13.0, *) {
            do {
                stream = try StreamLocation()
            } catch {}
            let publisher = stream?.subject
            stream?.start()
            DispatchQueue.main.async {
                self.cancellable = publisher?.sink { location in
                    self.logger.log("\(location.coordinate.latitude)-\(location.coordinate.longitude)")
                }
            }
        }
    }

    @IBAction func startForeground(_: UIButton) {
        stream?.startForeground()
    }

    @IBAction func startBackground(_: UIButton) {
        stream?.startBackground()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func stopButton(_: Any) {
        stream?.stopUpdates()
    }
}
