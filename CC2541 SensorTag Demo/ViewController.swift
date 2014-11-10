//
//  ViewController.swift
//  CC2541 SensorTag Demo
//
//  Created by Philip Bale on 11/9/14.
//  Copyright (c) 2014 Philip Bale. All rights reserved.
//

import UIKit
import CoreBluetooth;

class ViewController: UIViewController {
    
    @IBOutlet weak var connectedStatus: UILabel!
    @IBOutlet weak var ambientTemp: UILabel!
    @IBOutlet weak var irTemp: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        connectedStatus.text = "false"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

