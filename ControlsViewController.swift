//
//  ControlsViewController.swift
//  Project Beach Titan
//
//  Created by Mark Eaton on 7/19/16.
//  Copyright © 2016 Mark Eaton. All rights reserved.
//

import UIKit
import CoreBluetooth

class ControlsViewController: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {


    @IBOutlet weak var viewDirectionField: UIView!
    @IBOutlet weak var dashboard: UICollectionView!
    
    var labelAngle: UILabel?
    var labelPower: UILabel?
    
    var angleInDegTarget: Double = 0.0
    var angleInDegCurrent: Double = 0.0
    
    var powerTarget: Int = 0
    var powerCurrent: Int = 0
    
    var powerLock = false
    
    var lengthDirectionPadBaseDiameter: CGFloat!
    var lengthDirectionPadStickDiameter: CGFloat!
    var viewDirectionPadStick: UIView?
    var viewBluetoothConnection: UIImageView?
    var viewCruiseControl: UIImageView?
    var bluetoothOn = false
    var viewDirectionPadBase: DirectionPadBaseView?
    var origin: CGPoint?
    var cruiseControlOn = false
    var directionPadIsActive = false
    
    // Colors
    
    var colorBlueWithAlpha = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 0.4)
    var colorBlue = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1.0)
    
    var colorGreenWithAlpha = UIColor(red: 0/255, green: 255/255, blue: 128/255, alpha: 0.4)
    var colorGreen = UIColor(red: 0/255, green: 255/255, blue: 128/255, alpha: 1.0)
    
    var colorRedWithAlpha = UIColor(red: 255/255, green: 102/255, blue: 102/255, alpha: 0.4)
    var colorRed = UIColor(red: 255/255, green: 102/255, blue: 102/255, alpha: 1.0)
    
    //Gestures
    
    var tap: UITapGestureRecognizer!
    
    //Timers
    
    var steeringTimer: NSTimer!
    var powerTimer: NSTimer!
    
    // Core Bluetooth
    
    var centralManager: CBCentralManager!
    var beachTitanPeripheral: CBPeripheral?
    var characteristicSteering: CBCharacteristic?
    var characteristicPower: CBCharacteristic?
    let service = CBUUID(string: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFF0")

    //MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Beach Titan"
        lengthDirectionPadBaseDiameter = self.view.bounds.width * 2/3
        lengthDirectionPadStickDiameter = lengthDirectionPadBaseDiameter * 1/2
        
        tap = UITapGestureRecognizer(target: self, action: #selector(directionPadFieldTapped))
       
        dashboard.delegate = self
        dashboard.dataSource = self
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        labelAngle?.text! = "0°"
        labelPower?.text! = "0%"
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
         UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Disconnect Bluetooth
        
        if beachTitanPeripheral != nil{
            centralManager.cancelPeripheralConnection(beachTitanPeripheral!)
        }
        
    }
    
    //MARK: Touches
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("began")
        
        if let touch = touches.first {
        
            let tag = touch.view!.tag
            
            if tag == 1 {
                
                if !directionPadIsActive {
                    
                    steeringStartTimer()
                    powerStartTimer()
                    
                    directionPadIsActive = true
                    
                    viewDirectionField.addGestureRecognizer(tap)
                
                    origin = touch.locationInView(viewDirectionField)
                    
                    viewDirectionPadBase = DirectionPadBaseView(frame: CGRect(x: origin!.x - lengthDirectionPadBaseDiameter/2, y: origin!.y - lengthDirectionPadBaseDiameter/2, width: lengthDirectionPadBaseDiameter, height: lengthDirectionPadBaseDiameter))
                    
                    viewDirectionPadStick = UIView(frame: CGRect(x: origin!.x - lengthDirectionPadStickDiameter/2, y: origin!.y - lengthDirectionPadStickDiameter/2, width: lengthDirectionPadStickDiameter, height: lengthDirectionPadStickDiameter))
                    
                    viewDirectionPadBase!.backgroundColor = UIColor.clearColor()
                    
                    viewDirectionPadStick!.layer.masksToBounds = true
                    viewDirectionPadStick!.layer.cornerRadius = lengthDirectionPadStickDiameter/2
                    viewDirectionPadStick!.backgroundColor = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1.0)
                    
                    viewDirectionField.addSubview(viewDirectionPadBase!)
                    viewDirectionField.addSubview(viewDirectionPadStick!)
                }
                }
            }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        var localPower = 0
        
        if let touch = touches.first{
            let touchPt = touch.locationInView(viewDirectionField)
            
            let xDelta = (origin!.x - touchPt.x)
            let yDelta = (origin!.y - touchPt.y)
            
            let angleInRad = atan(yDelta/xDelta)
           
            let magnitude = sqrt(pow(xDelta, 2.0) + pow(yDelta, 2.0))
            

            if magnitude <= lengthDirectionPadBaseDiameter/2 {
                
                viewDirectionPadStick?.center = touchPt
                localPower = Int(round(magnitude/(lengthDirectionPadBaseDiameter/2) * 100.0))
                
                if xDelta > 0 && yDelta > 0{
                    angleInDegTarget = (M_PI - Double(angleInRad)) * 180 / M_PI
                    labelAngle?.text! = "\(Int(round(angleInDegTarget)))°"
                } else if xDelta > 0 && yDelta < 0{
                    angleInDegTarget = (M_PI - Double(angleInRad)) * 180 / M_PI
                    labelAngle?.text! = "\(Int(round(angleInDegTarget)))°"
                    localPower = -localPower
                } else if xDelta < 0 && yDelta > 0{
                    angleInDegTarget = Double(angleInRad) * 180 / M_PI
                    labelAngle?.text! = "\(-Int(round(angleInDegTarget)))°"
                } else if xDelta < 0 && yDelta < 0{
                    angleInDegTarget = (2 * M_PI - Double(angleInRad)) * 180 / M_PI
                    labelAngle?.text! = "\(Int(round(angleInDegTarget)))°"
                    localPower = -localPower
                }
                
            } else {
                
                if yDelta < 0 {
                    localPower = -100
                } else {
                    localPower = 100
                }
                
                 labelPower?.text! = "\(abs(powerTarget))%"
                
                var x: CGFloat = cos(angleInRad) * lengthDirectionPadBaseDiameter/2
                var y: CGFloat = sin(angleInRad) * lengthDirectionPadBaseDiameter/2
                
                if xDelta > 0 && yDelta > 0{
                    x = -x
                    y = -y
                    angleInDegTarget = (M_PI - Double(angleInRad)) * 180.0 / M_PI
                    labelAngle?.text! = "\(Int(round(angleInDegTarget)))°"
                } else if xDelta > 0 && yDelta < 0{
                    x = -x
                    y = -y
                    angleInDegTarget = (M_PI - Double(angleInRad)) * 180.0 / M_PI
                    labelAngle?.text! = "\(Int(round(angleInDegTarget)))°"
                } else if xDelta < 0 && yDelta > 0{
                    angleInDegTarget = Double(angleInRad) * 180.0 / M_PI
                    labelAngle?.text! = "\(-Int(round(angleInDegTarget)))°"
                } else if xDelta < 0 && yDelta < 0{
                    angleInDegTarget = (2 * M_PI - Double(angleInRad)) * 180.0 / M_PI
                    labelAngle?.text! = "\(Int(round(angleInDegTarget)))°"
                }
               
                let point = CGPoint(x: origin!.x + x,y: origin!.y + y)
                
                if !cruiseControlOn{
                    viewDirectionPadStick?.center = point
                }
            }
            
            if !powerLock{
                powerTarget = localPower
                labelPower?.text! = "\(abs(powerTarget))%"
            }
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        print("canceled")
        
        if !cruiseControlOn{
            removeDirectionPadView()
        }
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("ended")
        if !cruiseControlOn{
            removeDirectionPadView()
        } else {
            viewDirectionPadStick!.center.x = origin!.x
            labelAngle?.text! = "90°"
            angleInDegTarget = 90.0
            steeringUpdate()
        }
    }
    
    func removeDirectionPadView(){

        for view in viewDirectionField.subviews{
            view.removeFromSuperview()
        }
        
        if powerLock{
            updatePowerLabel()
        }
        
        labelAngle?.text! = "0°"
        labelPower?.text! = "0%"
        
        directionPadIsActive = false
        viewDirectionField.gestureRecognizers?.removeAll()
    
        //Reset Heading

        angleInDegTarget = 90.0
        steeringUpdate()
        steeringEndTimer()
    
        //Reset Power
        
        powerTarget = 0
        powerUpdate()
        powerEndTimer()
    }
    
    //MARK: Beach Titan - Steering
    
    func steeringStartTimer(){
        steeringTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(steeringUpdate), userInfo: nil, repeats: true)
    }
    
    func steeringUpdate(){
        
        var angleAsString = ""
        
        if (angleInDegTarget != angleInDegCurrent) {
            angleInDegCurrent = angleInDegTarget
            if angleInDegTarget > 180 {
                angleAsString = abs(Int(360 - angleInDegTarget)).description
            } else{
                angleAsString = abs(Int(angleInDegTarget)).description
            }
            let data: NSData = angleAsString.dataUsingEncoding(NSUTF8StringEncoding)!
            beachTitanPeripheral?.writeValue(data, forCharacteristic: characteristicSteering!, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func steeringEndTimer(){
        steeringTimer.invalidate()
    }
    
    //MARK: Beach Titan - Power
    
    func powerStartTimer(){
        powerTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(powerUpdate), userInfo: nil, repeats: true)
    }
    
    func powerUpdate(){
        
        if (powerTarget != powerCurrent){
            powerCurrent = powerTarget
            let powerAsString = powerTarget.description
            let data: NSData = powerAsString.dataUsingEncoding(NSUTF8StringEncoding)!
            beachTitanPeripheral?.writeValue(data, forCharacteristic: characteristicPower!, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func powerEndTimer(){
        steeringTimer.invalidate()
    }
    
    func updatePowerLabel(){
        
        powerLock = !powerLock
        
        if powerLock{
            print("Power Lock: On")
            labelPower?.textColor = colorRed
        } else{
            print("Power Lock: Off")
            labelPower?.textColor = colorGreen
        }
    }
    
    
    //MARK: Cruise Control
    
    func activateCruiseControl(){
        print("cruise control on")
        cruiseControlOn = true
        viewDirectionPadBase?.pathColor = colorGreenWithAlpha
        viewDirectionPadStick?.backgroundColor = colorGreen
        viewDirectionPadBase?.setNeedsDisplay()
        viewCruiseControl?.image! = UIImage(named: "cruiseActive")!
    }
    
    func deactivateCruiseControl(){
        cruiseControlOn = false
        viewDirectionPadBase?.pathColor = colorBlueWithAlpha
        viewDirectionPadStick?.backgroundColor = colorBlue
        viewDirectionPadBase?.setNeedsDisplay()
        viewCruiseControl?.image! = UIImage(named: "cruiseInactive")!
    }
    
    func directionPadFieldTapped(sender: UITapGestureRecognizer){
        
        if directionPadIsActive{
            if cruiseControlOn{
                deactivateCruiseControl()
            }else{
                activateCruiseControl()
            }
        }
    }

    //MARK: Core Bluetooth - Central Manager
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("connected to Beach Titan")
        peripheral.discoverServices(nil)
        
        bluetoothOn = true
        viewBluetoothConnection?.image = UIImage(named: "bluetoothActive")
        beachTitanPeripheral = peripheral
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?){
        bluetoothOn = false
        viewBluetoothConnection?.image = UIImage(named: "bluetoothInactive")
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        
        if localName == "Beach Titan" {
            print("Found Beach Titan.")
            centralManager.stopScan()
            beachTitanPeripheral = peripheral
            beachTitanPeripheral?.delegate = self
            centralManager.connectPeripheral(beachTitanPeripheral!, options: nil)
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        switch central.state{
        case .PoweredOff:
            print("Hardware is Powered Off.")
            viewBluetoothConnection?.image = UIImage(named: "bluetoothInactive")
            bluetoothOn = false
        case .PoweredOn:
            print("Hardware is Powered On. Scanning for peripherals...")
            centralManager.scanForPeripheralsWithServices([service], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        case .Resetting:
            print("Hardware is Resetting.")
        case .Unauthorized:
            print("Hardware is Unauthorized.")
        case .Unknown:
            print("Hardware is Unknown.")
        case .Unsupported:
            print("Hardware is Unsupported.")
        }
    }
    
    //MARK: Core Bluetooth - Peripheral Device (Beach Titan)
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Found \((peripheral.services?.count)!) Beach Titan Services")
        if let service = peripheral.services?.first{
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Found \((service.characteristics?.count)!) Beach Titan Characteristics")
        
        let uuidSteering: CBUUID = CBUUID(string: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFF4")
        let uuidPower: CBUUID = CBUUID(string: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFF8")
        
        for char in service.characteristics!{
            switch char.UUID{
            case uuidSteering:
                characteristicSteering = char
            case uuidPower:
                characteristicPower = char
            default:
                break
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateValueForCharacteristic")
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        print("peripheralDidUpdateRSSI")
    }
    

    //MARK: Collection View - Dashboard
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        print(indexPath.item)
        
        switch indexPath.item{
        case 0:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("iconWithLabel", forIndexPath: indexPath) as! IconWithLabelCollectionViewCell
            cell.labelIcon.text = "Bluetooth"
            viewBluetoothConnection = cell.imageViewIcon
            if bluetoothOn{
                viewBluetoothConnection?.image! = UIImage(named: "bluetoothActive")!
            }else{
                viewBluetoothConnection?.image! = UIImage(named: "bluetoothInactive")!
            }
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("labelWithLabel", forIndexPath: indexPath) as! LabelWithLabelCollectionViewCell
            cell.labelLower.text! = "Heading"
            labelAngle = cell.labelUpper
            labelAngle?.text = "0°"
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("labelWithLabel", forIndexPath: indexPath) as! LabelWithLabelCollectionViewCell
            cell.labelLower.text! = "Power"
            labelPower = cell.labelUpper
            labelPower?.text = "0%"
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("iconWithLabel", forIndexPath: indexPath) as! IconWithLabelCollectionViewCell
            cell.labelIcon.text = "Cruise"
            viewCruiseControl = cell.imageViewIcon
            if cruiseControlOn{
                viewCruiseControl!.image! = UIImage(named: "cruiseActive")!
            }else{
               viewCruiseControl!.image! = UIImage(named: "cruiseInactive")!
            }
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("iconWithLabel", forIndexPath: indexPath) as! IconWithLabelCollectionViewCell
            cell.labelIcon.text = "GPS"
            viewCruiseControl = cell.imageViewIcon
            viewCruiseControl!.image! = UIImage(named: "gpsInactive")!
            return cell
        default:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("iconWithLabel", forIndexPath: indexPath) as! IconWithLabelCollectionViewCell
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.item{
        case 0:
            if beachTitanPeripheral?.state == .Disconnected {
                centralManager.scanForPeripheralsWithServices([service], options: nil)
            } else if beachTitanPeripheral?.state == .Connected {
                centralManager.cancelPeripheralConnection(beachTitanPeripheral!)
            }
        case 2:
            updatePowerLabel()
        case 3:
            if cruiseControlOn{
                deactivateCruiseControl()
                removeDirectionPadView()
            }else {
                activateCruiseControl()
            }
        default:
            break
        }
    }
}

class DirectionPadBaseView: UIView {
    
    var pathColor = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 0.4)
    
    override func drawRect(rect: CGRect) {
        
        let lineWidth: CGFloat = 25.0
        let radius = (bounds.width)/2
        let modifiedRadius = (bounds.width - lineWidth)/2
        let center = CGPoint(x: radius, y: radius)
        let path = UIBezierPath(ovalInRect: CGRect(x: center.x - modifiedRadius, y: center.y - modifiedRadius, width: 2 * modifiedRadius, height: 2 * modifiedRadius))
        
    
        path.lineWidth = lineWidth
        pathColor.setStroke()
        path.stroke()
    }
}

