//
//  NAULoginController.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 17/08/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import Alamofire

class NAULoginController: UIViewController, UITextFieldDelegate {
    
    private var availableIPAddress:String?

    @IBOutlet weak var pinTextField: SkyFloatingLabelTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pin Login"
        pinTextField.textAlignment = .center
        pinTextField.delegate = self
        
        if let ip = WifiGatewayIP.getGatewayIP(){
        let subnetBlocks =  ip.components(separatedBy: ".")
        let networkAddress = subnetBlocks[0] + "." + subnetBlocks[1] + "." + subnetBlocks[2] + "."
        let host = (Int(subnetBlocks[3]) ?? 1) + 1
        findAvailableIP(with:networkAddress,host)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @IBAction func submitPin(_ sender: UIButton) {
        if let pin = pinTextField.text, !pin.isEmpty{
            if pinFormatIsValid(pin){
                if let ip = availableIPAddress,let url = URL(string: "http://" + ip + ":4563/auth"){
                    AmahiApi.shared.login(pin: pin, url: url) { (success, authToken) in
                        DispatchQueue.main.async {
                            ServerApi.shared?.auth_token = authToken
                            let address = "http://"+ip+":4563"
                            ServerApi.shared?.serverAddress = address
                            
//                            let hdaCache = HDAAuthCache(ip: ip, nil, authToken, address)
//                            let dict = hdaCache.toDictionary
//                            var authCache = LocalStorage.shared.getDictionaryArray(for: PersistenceIdentifiers.hdaAuthCache) as? [[String:String]]
//                            if authCache != nil{
//                                authCache?.append(dict)
//                            }
//                            
//                            LocalStorage.shared.persistDictionaryArray(authCache ?? [dict], for: PersistenceIdentifiers.hdaAuthCache)
                            LocalStorage.shared.persist(true, for: PersistenceIdentifiers.isNAULogin)
                            self.setupViewController()
                        }
                    }
                }
            }else{
                pinTextField.errorColor = .red
                pinTextField.errorMessage = "A 3-5 digit alpha-numeric pin is expected!"
            }
        }else{
            pinTextField.errorColor = .red
            pinTextField.errorMessage = "Please enter a pin to continue!"
        }
    }
    
    private func setupViewController(){
        if let rootVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootVC") as? RootContainerViewController{
            
            rootVC.isNAULogin = true
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let currentWindow =  appDelegate.window{
               UIView.transition(with: currentWindow, duration: 0.3, options: .transitionFlipFromRight, animations: {
                    currentWindow.rootViewController = rootVC
                    currentWindow.makeKeyAndVisible()
               }, completion: nil)
            }
        }
    }
    
    private func pinFormatIsValid(_ testString:String)->Bool{
        //evaluating pin regular expression
        let pinExpression = "[A-Za-z0-9]+"
        let pinTest = NSPredicate(format:"SELF MATCHES %@",pinExpression)
        let expressionResult = pinTest.evaluate(with: testString)
        
        var isPinLengthValid = false
        (testString.count >= 3 && testString.count <= 5) ? (isPinLengthValid = true) : (isPinLengthValid = false)
        
        return isPinLengthValid && expressionResult
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        (textField as! SkyFloatingLabelTextField).errorMessage = nil
        return true
    }
    
    func findAvailableIP(with networkAddress: String,_ host : Int){
        if host > 255 || host < 0 || self.availableIPAddress != nil{
            return
        }
        let ip = networkAddress + "\(host)"
        Network.shared.pingOnce(ip) { (success) in
            DispatchQueue.main.async {
                print("\n--------------\n")
                print(success)
                print(ip)
                print("\n---------------\n")
                if success{
                    self.availableIPAddress = ip
                }else{
                    self.findAvailableIP(with: networkAddress, host+1)
                }
            }
        }
    }
}
