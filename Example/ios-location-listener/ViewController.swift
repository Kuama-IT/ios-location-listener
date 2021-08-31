//
//  ViewController.swift
//  ios-location-listener
//
//  Created by cc51a8303047eb6bf025205b97c4fbcf51205233 on 08/02/2021.
//  Copyright (c) 2021 cc51a8303047eb6bf025205b97c4fbcf51205233. All rights reserved.
//

import UIKit
import Combine
import ios_location_listener
import os.log

class ViewController: UIViewController {

    let logger = Logger(subsystem: "net.kuama.ios-location-listener", category: "kuama")
    let stream = StreamLocation()
    var cancellable: AnyCancellable? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            try listenToPosition()
        } catch {
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.

    }

    private func listenToPosition() throws {
        if #available(iOS 13.0, *) {

            let publisher = stream.subject
            try stream.setKilledAppUpdateDelay(updateDelay: 4)
            try stream.start()
            DispatchQueue.main.async {
                self.cancellable = publisher.sink {
                    s in
                    self.logger.log("\(s.coordinate.latitude)-\(s.coordinate.longitude)")
                }
            }

        }

    }
}

