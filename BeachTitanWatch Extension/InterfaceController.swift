//
//  InterfaceController.swift
//  BeachTitanWatch Extension
//
//  Created by Mark Eaton on 7/25/16.
//  Copyright © 2016 Mark Eaton. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController{

    @IBOutlet var pickerHeading: WKInterfacePicker!
    @IBOutlet var buttonDirectionOfMotor: WKInterfaceButton!
    
    var motorForward = false
    
    //Colors
    
        var colorRed = UIColor(red: 255/255, green: 102/255, blue: 102/255, alpha: 1.0)
        var colorGreen = UIColor(red: 0/255, green: 255/255, blue: 128/255, alpha: 1.0)
    
    var images: [WKImage] = [(WKImage(imageName: "0deg.png")), (WKImage(imageName: "30deg.png")), (WKImage(imageName: "45deg.png")), (WKImage(imageName: "60deg.png")), (WKImage(imageName: "90deg.png")), (WKImage(imageName: "120deg.png")), (WKImage(imageName: "135deg.png")), (WKImage(imageName: "150deg.png")), (WKImage(imageName: "180deg.png"))]
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        let pickerItems: [WKPickerItem] = images.map {
            let pickerItem = WKPickerItem()
            pickerItem.contentImage = $0
            pickerItem.caption = $0.imageName!
            return pickerItem
        }
        
        pickerHeading.setItems(pickerItems)
        pickerHeading.setSelectedItemIndex(4)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func changeDirection() {
        if motorForward{
            buttonDirectionOfMotor.setTitle(("R"))
        } else {
            buttonDirectionOfMotor.setTitle(("F"))
        }
        motorForward = !motorForward
    }
}
