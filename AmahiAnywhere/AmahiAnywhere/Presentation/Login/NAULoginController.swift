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
    private var isPingingIP:Bool = false{
        willSet{
            if !newValue && loginWaitingForIP{
                hideDelay()
                loginUser()
            }
        }
    }
    private var loginWaitingForIP = false
    private var userPin :String = ""
    private let pinExpression = "[A-Za-z0-9]+"
    
    @IBOutlet weak var pinTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var delayLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pin Login"
        pinTextField.textAlignment = .center
        pinTextField.delegate = self
        
        pingCachedIP()
        probeServerIP()
        
        delayLabel.alpha = 0
        view.bringSubviewToFront(titleLabel)
    }
    
    func probeServerIP(){
        if availableIPAddress == nil{
            if let defaultGateway = WifiGatewayIP.getGatewayIP(){
                let gatewayBlocks = defaultGateway.components(separatedBy: ".")
                let localSubnet = gatewayBlocks[0] + "." + gatewayBlocks[1] + "." + gatewayBlocks[2] + "."
                let startingHost = (Int(gatewayBlocks[3]) ?? 1) + 1
                findAvailableIP(with: localSubnet, startingHost)
            }else{
                //show could not locate gateway.
                showAlert(withTitle: "Could not locate router address!", message: "Please make sure wifi is connected.", actions: [UIAlertAction(title: "ok", style: .default, handler: nil)])
            }
        }
    }
    
    private func pingCachedIP(){
        if let hac = LocalStorage.shared.getDictionary(for: PersistenceIdentifiers.hdaAuthCache){
            isPingingIP = true
            for cachedIP in hac.keys {
                if availableIPAddress != nil{
                    break
                }
                Network.shared.pingOnce(cachedIP) { (success) in
                    if success{
                        AmahiLogger.log("Sucessfully pinged IP for NAU")
                        self.availableIPAddress = cachedIP
                        self.isPingingIP = false
                    }
                }
            }
            isPingingIP = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(named:"tabBarBackground")
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(named:"textOpenColor")]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @IBAction func submitPin(_ sender: UIButton) {
        if let pin = pinTextField.text, !pin.isEmpty{
            if pinFormatIsValid(pin){
                userPin = pin
                if availableIPAddress != nil{
                    showLoader()
                    loginUser()
                    return
                }
                //if no IP is found yet
                if !isPingingIP{
                    showAlert(withTitle: "Failed to locate HDA server!", message: nil,
                              actions: [UIAlertAction(title: "try again?", style: .default, handler: { (_) in
                                self.probeServerIP()
                                self.showLoader()
                              }),
                                UIAlertAction(title: "continue with username", style: .default, handler: { (_) in
                                    self.navigationController?.popViewController(animated: true)
                                })])
                }else{
                    //wait for IP
                    showLoader()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {[weak self] in
                        self?.showDelay()
                    }
                    loginWaitingForIP = true
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
    
    private func loginUser(){
        loginWaitingForIP = false
        if let ip = availableIPAddress,let url = ApiEndPoints.getNauAuthUrl(from: ip){
            AmahiApi.shared.login(pin: userPin, url: url) { (success, authToken) in
                DispatchQueue.main.async {
                    if success{
                        self.hideLoader()
                        ServerApi.shared?.auth_token = authToken
                        let address = ApiEndPoints.getNauAddress(from: ip)
                        ServerApi.shared?.serverAddress = address
                        
                        let serverCache = HDAAuthCache(ip: ip, sessionToken: nil, authToken: authToken, serverAddress: address)
                        
                        LocalStorage.shared.persistDictionary([ip:serverCache.toDictionary], for: PersistenceIdentifiers.hdaAuthCache)
                        LocalStorage.shared.persist(true, for: PersistenceIdentifiers.isNAULogin)
                        self.setupViewController()
                    }else{
                        self.showAlert(withTitle: "Pin authentication failed!", message: "Please enter the correct pin.", actions: [UIAlertAction(title: "try again", style: .default, handler: nil)])
                    }
                }
            }
        }else{
            showAlert(withTitle: "Failed to locate HDA server!", message: nil,
            actions: [UIAlertAction(title: "try again?", style: .default, handler: { (_) in
                self.showLoader()
              self.probeServerIP()
            }),
              UIAlertAction(title: "continue with username", style: .default, handler: { (_) in
                  self.navigationController?.popViewController(animated: true)
              })])
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
        isPingingIP = true
        if host > 255 || host < 0 || self.availableIPAddress != nil{
            isPingingIP = false
            return
        }
        let ip = networkAddress + "\(host)"
        Network.shared.pingOnce(ip) { [weak self] (success) in
            DispatchQueue.main.async {
                AmahiLogger.log("Sucessfully pinged IP for NAU")
                if success{
                    self?.availableIPAddress = ip
                }else{
                    self?.findAvailableIP(with: networkAddress, host+1)
                }
            }
        }
    }
    
    private func showAlert(withTitle title:String?,message:String?,actions:[UIAlertAction]){
        hideLoader()
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions{
            alertController.addAction(action)
        }
        present(alertController, animated: true)
    }
    
    private func showLoader(){
        loaderView.startAnimating()
        submitButton.isEnabled = false
        pinTextField.isEnabled = false
        submitButton.setTitle("", for: .normal)
    }
    
    private func hideLoader(){
        loaderView.stopAnimating()
        submitButton.isEnabled = true
        pinTextField.isEnabled = true
        submitButton.setTitle("SUBMIT", for: .normal)
    }
    
    private func showDelay(){
        UIView.animate(withDuration: 1) {[weak self] in
            self?.view.bringSubviewToFront(self!.delayLabel)
            self?.titleLabel.alpha = 0
            self?.delayLabel.alpha = 1
        }
    }
    
    private func hideDelay(){
        UIView.animate(withDuration: 1) {[weak self] in
            self?.view.bringSubviewToFront(self!.titleLabel)
            self?.titleLabel.alpha = 0
            self?.delayLabel.alpha = 1
        }
    }
}
