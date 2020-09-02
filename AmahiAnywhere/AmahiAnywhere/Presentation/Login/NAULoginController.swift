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
    
    private var availableIPAddress = Set<String>()
    private var isPingingIP:Bool = false{
        willSet{
            if !newValue{
                hideLoader()
                if loginWaitingForIP{
                    hideDelay()
                    loginUser()
                }
            }
        }
    }
    private var loginWaitingForIP = false
    private var userPin :String = ""
    private let pinExpression = "[A-Za-z0-9]+"
    private var userAuthenticated = false
    
    @IBOutlet weak var pinTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var delayLabel: UILabel!
    
    private let pingDispatchGroup = DispatchGroup()
    private let cacheDispatchGroup = DispatchGroup()
    private let loginDispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PIN Login"
        pinTextField.textAlignment = .center
        pinTextField.delegate = self
        
        pingCachedIP()
        probeServerIP()
        
        delayLabel.alpha = 0
        view.bringSubviewToFront(titleLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let routerIP = WifiGatewayIP.getGatewayIP()
        if routerIP == nil{
            showAlert(withTitle: "Could not locate wifi router!", message: "Please make sure wifi is connected.", actions: [UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            })])
        }
        NotificationCenter.default.addObserver(self, selector: #selector(unreachableHDA), name: .HDAUnreachable, object: nil)
    }
    
    @objc func unreachableHDA(){
        let alertVC = UIAlertController(title: "Unable to reach HDA", message: "Please check if your HDA is connected and try again.", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func probeServerIP(){
        if availableIPAddress.isEmpty{
            if let defaultGateway = WifiGatewayIP.getGatewayIP(){
                let gatewayBlocks = defaultGateway.components(separatedBy: ".")
                let localSubnet = gatewayBlocks[0] + "." + gatewayBlocks[1] + "." + gatewayBlocks[2] + "."
                let startingHost = (Int(gatewayBlocks[3]) ?? 1) + 1
                findAvailableIP(with: localSubnet, startingHost)
            }
        }
    }
    
    private func pingCachedIP(){
        if let hac = LocalStorage.shared.getDictionary(for: PersistenceIdentifiers.hdaAuthCache){
            isPingingIP = true
            for cachedIP in hac.keys {
                cacheDispatchGroup.enter()
                DispatchQueue.init(label: "cacheQueueFor_\(cachedIP)").async {
                    Network.shared.pingOnce(cachedIP,timeout: 1.2) { (success) in
                        if success{
                            DispatchQueue.main.async {
                                AmahiLogger.log("Sucessfully pinged Cached IP :" + cachedIP + " for NAU")
                                self.availableIPAddress.insert(cachedIP)
                            }
                        }
                        self.cacheDispatchGroup.leave()
                    }
                }
            }
            cacheDispatchGroup.notify(queue: .main) { [weak self] in
                self?.isPingingIP = false
            }
        }
    }
    
    @IBAction func cancelButtonTap(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
                if !availableIPAddress.isEmpty{
                    showLoader()
                    loginUser()
                    return
                }
                
                if !isPingingIP{
                    showAlert(withTitle: "Failed to locate HDA server!", message: nil,
                              actions: [UIAlertAction(title: "Try again?", style: .default, handler: { (_) in
                                self.probeServerIP()
                                self.showLoader()
                              }),
                                UIAlertAction(title: "continue with username", style: .default, handler: { (_) in
                                    self.dismiss(animated: true, completion: nil)
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
        
        if availableIPAddress.isEmpty{
            showAlert(withTitle: "Failed to locate HDA server!", message: nil,
                        actions: [UIAlertAction(title: "Try again?", style: .default, handler: { (_) in
                                self.probeServerIP()
                                self.showLoader()
                              }),
                                UIAlertAction(title: "continue with username", style: .default, handler: { (_) in
                                    self.navigationController?.popViewController(animated: true)
                                })])
        }
        
        for ip in availableIPAddress{
            if let url = ApiEndPoints.getNauAuthUrl(from: ip){
                loginDispatchGroup.enter()
                AmahiApi.shared.login(pin: userPin, url: url) { (success, authToken) in
                    DispatchQueue.main.async { [weak self] in
                        self?.loginDispatchGroup.leave()
                        if success{
                            self?.hideLoader()
                            ServerApi.shared?.auth_token = authToken
                            let address = ApiEndPoints.getNauAddress(from: ip)
                            ServerApi.shared?.serverAddress = address
                            
                            let authCache = HDAAuthCache(ip: ip, sessionToken: nil, authToken: authToken, serverAddress: address)
                            var storedCache = LocalStorage.shared.getDictionary(for: PersistenceIdentifiers.hdaAuthCache)
                            if storedCache != nil{
                                storedCache![ip] = authCache.toDictionary
                                LocalStorage.shared.persistDictionary(storedCache!, for: PersistenceIdentifiers.hdaAuthCache)
                            }else{
                                LocalStorage.shared.persistDictionary([ip:authCache.toDictionary], for: PersistenceIdentifiers.hdaAuthCache)
                            }
                            LocalStorage.shared.persist(true, for: PersistenceIdentifiers.isNAULogin)
                            self?.setupViewController()
                            self?.userAuthenticated = true
                            AmahiLogger.log("Successfully Logged in NAU on IP: " + ip)
                        }else{
                            if let userIsAuthenticated = self?.userAuthenticated, !userIsAuthenticated{
                                self?.userAuthenticated = false
                            }
                            AmahiLogger.log("NAU login failed for IP: " + ip)
                        }
                    }
                }
            }
        }
        
        loginDispatchGroup.notify(queue: .main) { [weak self] in
            if let userIsAuthenticated = self?.userAuthenticated, !userIsAuthenticated{
                self?.showAlert(withTitle: "Authentication failed!", message: "Please enter a valid PIN", actions: [UIAlertAction(title: "Ok", style: .default, handler: nil)])
            }
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
        var hostDevice = host
        while hostDevice <= 255{
            isPingingIP = true
            pingDispatchGroup.enter()
            
            let ip = networkAddress + "\(hostDevice)"
            
            DispatchQueue.init(label: "queueFor\(hostDevice)").async {
                Network.shared.pingOnce(ip,timeout: 1.2) { [weak self] (success) in
                    DispatchQueue.main.async {
                        if success{
                            AmahiLogger.log("Sucessfully pinged IP : " + ip + " for NAU")
                            self?.availableIPAddress.insert(ip)
                        }
                        self?.pingDispatchGroup.leave()
                    }
                }
            }
            hostDevice += 1
        }
        
        pingDispatchGroup.notify(queue: .main) {
            self.isPingingIP = false
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
