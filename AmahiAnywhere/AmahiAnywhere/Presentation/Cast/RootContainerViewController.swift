//
//  RootContainerViewController.swift
//  AmahiAnywhere
//
//  Created by Abhishek Sansanwal on 23/07/19.
//  Copyright © 2019 Amahi. All rights reserved.
//

import GoogleCast
import UIKit
import LocalAuthentication

let kCastControlBarsAnimationDuration: TimeInterval = 0.20

@objc(RootContainerViewController)
class RootContainerViewController: UIViewController, GCKUIMiniMediaControlsViewControllerDelegate {
    @IBOutlet private var _miniMediaControlsContainerView: UIView!
    @IBOutlet private var _miniMediaControlsHeightConstraint: NSLayoutConstraint!
    private var miniMediaControlsViewController: GCKUIMiniMediaControlsViewController!
    var miniMediaControlsViewEnabled = false {
        didSet {
            if isViewLoaded {
                updateControlBarsVisibility()
            }
        }
    }
    
    var overridenNavigationController: UINavigationController?
    var biometricAuthOverride:Bool{
        return LocalStorage.shared.getBool(for: PersistenceIdentifiers.overrideBiometric)
    }
    private var isAskingForBiometric = false
    override var navigationController: UINavigationController? {
        get {
            return overridenNavigationController
        }
        set {
            overridenNavigationController = newValue
        }
    }
    
    var miniMediaControlsItemEnabled = false
    
    lazy var blurrEffect : UIVisualEffectView = {
        var blur : UIBlurEffect?
        if #available(iOS 13.0, *){
            blur = UIBlurEffect(style: .systemMaterial)
        }else{
            blur = UIBlurEffect(style: .regular)
        }
        let effectsView = UIVisualEffectView(effect: blur)
        return effectsView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let castContext = GCKCastContext.sharedInstance()
        miniMediaControlsViewController = castContext.createMiniMediaControlsViewController()
        miniMediaControlsViewController.delegate = self
        updateControlBarsVisibility()
        installViewController(miniMediaControlsViewController,
                              inContainerView: _miniMediaControlsContainerView)
        view.addSubview(blurrEffect)
        blurrEffect.translatesAutoresizingMaskIntoConstraints = false
        blurrEffect.setAnchors(top: view.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor, topConstant: 0, leadingConstant: 0, trailingConstant: 0, bottomConstant: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func applicationWillEnterForeground(){
        if isAskingForBiometric{
            initiateBiometricAuth()
            showBlurView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initiateBiometricAuth()
    }
    
    @objc func initiateBiometricAuth(){
       hideBlurrView()
       let localStorage = LocalStorage.shared
       if localStorage.contains(key: PersistenceIdentifiers.biometricLoginPermissionAsked){
           if localStorage.getBool(for: PersistenceIdentifiers.biometricLoginPermissionAsked)
               && localStorage.getBool(for: PersistenceIdentifiers.biometricEnabled) && !biometricAuthOverride{
               showBlurView()
               performBiometricAuth()
           }
    
           if biometricAuthOverride == true{
               localStorage.persist(bool: false, for: PersistenceIdentifiers.overrideBiometric)
               hideBlurrView()
           }
       }else{
           isAskingForBiometric = true
           showBlurView()
           let biometricAlert = UIAlertController(title: "Use Biometrics for Login?", message: "You can turn this off any time in app settings", preferredStyle: .alert)
           biometricAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
               localStorage.persist(bool: true, for: PersistenceIdentifiers.biometricEnabled)
               self.performBiometricAuth()
           }))
           biometricAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (_) in
               localStorage.persist(bool: false, for: PersistenceIdentifiers.biometricEnabled)
               DispatchQueue.main.async {
                   self.hideBlurrView()
               }
           }))
           present(biometricAlert, animated: true) {
               localStorage.persist(bool: true, for: PersistenceIdentifiers.biometricLoginPermissionAsked)
           }
       }
    }
        
    func performBiometricAuth(){
        isAskingForBiometric = true
        let context = LAContext()
        var error:NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error){
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Please identify yourself!") { (success, evaluationError) in
                DispatchQueue.main.async {
                    self.isAskingForBiometric = false
                    if success{
                        AmahiLogger.log("Biometric Succesfully verified")
                        self.hideBlurrView()
                    }else{
                        AmahiLogger.log(error?.localizedDescription)
                        if let error = evaluationError as? LAError {
                            print("\(error.code.rawValue): Shresth LAError")
                            switch error.code {
                            case .authenticationFailed:
                                let alert = UIAlertController(title: "Failed to authenticate user", message: "Too many unsuccessful attempts! Please login again.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                    LocalStorage.shared.logout{}
                                    LocalStorage.shared.persist(bool: true, for: PersistenceIdentifiers.overrideBiometric)
                                    self.signOut()
                                }))
                                self.present(alert, animated: true, completion: nil)
                            case .passcodeNotSet:
                                let alert = UIAlertController(title: "Passcode not set", message: "Please set a lockscreen passcode to login using Passcode", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                    LocalStorage.shared.logout{}
                                    LocalStorage.shared.persist(bool: true, for: PersistenceIdentifiers.overrideBiometric)
                                    self.signOut()
                                }))
                                self.present(alert, animated: true, completion: nil)
                            default:
                                LocalStorage.shared.logout{}
                                LocalStorage.shared.persist(bool: true, for: PersistenceIdentifiers.overrideBiometric)
                                self.signOut()
                            }
                        }
                    }
                }
            }
        }else{
            AmahiLogger.log(error?.localizedDescription ?? "Device is unable to configure biometric authorization")
            if let laError = error as? LAError{
                var errorTitle = "Could not initiate biometric Authentication"
                var errorDescription = "Please check your biometric/passcode setup in device settings and retry again."
                switch laError.errorCode {
                case LAError.Code.biometryNotEnrolled.rawValue:
                    errorTitle = "Biometry not available"
                    errorDescription = "Please enroll your touch/face ID in device settings"
                case LAError.Code.passcodeNotSet.rawValue:
                    errorTitle = "Could not initiate biometric authentication"
                    errorDescription = "Please set a lockscreen passcode."
                default:
                    break
                }
                 let alert = UIAlertController(title: errorTitle, message: errorDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "login with username/email", style: .default, handler: { (_) in
                    LocalStorage.shared.logout{}
                    LocalStorage.shared.persist(bool: true, for: PersistenceIdentifiers.overrideBiometric)
                    self.signOut()
                }))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showBlurView(){
        view.bringSubviewToFront(blurrEffect)
        UIView.animate(withDuration: 0.5,animations: {
            self.blurrEffect.alpha = 1
        })
    }
    
    func hideBlurrView(){
        UIView.animate(withDuration: 0.5, animations: {
             self.blurrEffect.alpha = 0
         })
    }
    
    func signOut() {
        self.dismiss(animated: false, completion: nil)
        let loginVc = self.viewController(viewControllerClass: LoginViewController.self, from: StoryBoardIdentifiers.main)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let currentWindow =  appDelegate.window{
            UIView.transition(with: currentWindow, duration: 0.3, options: .transitionFlipFromRight, animations: {
                currentWindow.rootViewController = loginVc
                currentWindow.makeKeyAndVisible()
            }, completion: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Internal methods
    
    func updateControlBarsVisibility() {
        if miniMediaControlsViewEnabled, miniMediaControlsViewController.active {
            NotificationCenter.default.post(name: .ShowMiniController, object: nil)
            _miniMediaControlsHeightConstraint.constant = miniMediaControlsViewController.minHeight
            view.bringSubviewToFront(_miniMediaControlsContainerView)
        } else {
            NotificationCenter.default.post(name: .HideMiniController, object: nil)
            _miniMediaControlsHeightConstraint.constant = 0
        }
        UIView.animate(withDuration: kCastControlBarsAnimationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        view.setNeedsLayout()
    }
    
    func installViewController(_ viewController: UIViewController?, inContainerView containerView: UIView) {
        if let viewController = viewController {
            addChild(viewController)
            viewController.view.frame = containerView.bounds
            containerView.addSubview(viewController.view)
            viewController.didMove(toParent: self)
        }
    }
    
    func uninstallViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "NavigationVCEmbedSegue" {
            if let tabBarController = segue.destination as? UITabBarController{
                tabBarController.selectedIndex = 1
            }
            navigationController = (segue.destination as? UINavigationController)
        }
    }
    
    // MARK: - GCKUIMiniMediaControlsViewControllerDelegate
    
    func miniMediaControlsViewController(_: GCKUIMiniMediaControlsViewController,
                                         shouldAppear _: Bool) {
        updateControlBarsVisibility()
    }
}
