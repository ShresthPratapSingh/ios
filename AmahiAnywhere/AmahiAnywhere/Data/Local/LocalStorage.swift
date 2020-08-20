//
//  LocalStorage.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 2/18/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation

final class LocalStorage: NSObject {
    
    private override init() {
        super.init()
    }
    
    static let shared = LocalStorage()
    
    public func persistString(string: String!, key: String!){
        delete(key: key);
        UserDefaults.standard.setValue(string, forKey: key);
        UserDefaults.standard.synchronize();
    }
    
    public func persistDictionary(_ dictionary:[String:[String:String]],for key: String){
        UserDefaults.standard.set(dictionary, forKey: key)
    }
    
    public func getDictionary(for key: String)->[String:[String:String]]?{
        return UserDefaults.standard.object(forKey: key) as? [String:[String:String]]
    }


    public func getString(key: String!) -> String? {
        UserDefaults.standard.synchronize()
        return UserDefaults.standard.value(forKey: key) as? String;
    }
    
    public func getBool(_ key:String) -> Bool{
        return UserDefaults.standard.bool(forKey: key)
    }
    
    public func persist(_ bool:Bool, for key:String){
        UserDefaults.standard.set(bool, forKey: key)
    }
    
    public func contains(key: String!) -> Bool{
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    public func delete(key: String!){
        UserDefaults.standard.removeObject(forKey: key);
        UserDefaults.standard.synchronize();
    }
    
    public func logout(_ complete: () -> Void){
        var hac = getDictionary(for: PersistenceIdentifiers.hdaAuthCache)
        clearAll()
        persistString(string: "completed", key: "walkthrough")
        
        //wiping auth_token for cached HDA
        if hac != nil{
            for ip in hac!.keys{
                hac![ip]?[HACIdentifiers.auth_token] = ""
            }
            persistDictionary(hac!, for: PersistenceIdentifiers.hdaAuthCache)
        }
        
        RecentsDatabaseHelper.shareInstance.clearAllRecents()
        complete()
    }
    
    public func clearAll(){
        let appDomain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
        UserDefaults.standard.synchronize()
    }
    
    public func getAccessToken() -> String? {
        return self.getString(key: PersistenceIdentifiers.accessToken)
    }
    
    public var userConnectionPreference : ConnectionMode {
        set {
            LocalStorage.shared.persistString(string: newValue.rawValue,
                                              key: PersistenceIdentifiers.prefConnection)
            ServerApi.shared?.configureConnection()
        }
        get {
            if let connection = LocalStorage.shared.getString(key: PersistenceIdentifiers.prefConnection) {
                return ConnectionMode(rawValue: connection)!
            } else {
                return ConnectionMode.auto
            }
        }
    }
}
