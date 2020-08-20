//
//  HACModel.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 17/08/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import Foundation
import EVReflection

struct HACIdentifiers{
    static let server_ip = "server_ip"
    static let session_token = "session_token"
    static let auth_token = "auth_token"
    static let server_address = "server_address"
}

struct HDAAuthCache{
    
    var serverLocalIP:String?
    var sessionToken:String?
    var authToken:String?
    var serverAddress:String?
    
    init(from dictionary:[String:String]) {
        serverLocalIP = (dictionary[HACIdentifiers.server_ip] == "") ? nil : dictionary[HACIdentifiers.server_ip]
        sessionToken = (dictionary[HACIdentifiers.session_token] == "") ? nil : dictionary[HACIdentifiers.session_token]
        authToken = (dictionary[HACIdentifiers.auth_token] == "") ? nil : dictionary[HACIdentifiers.auth_token]
        serverAddress = (dictionary[HACIdentifiers.server_address] == "") ? nil : dictionary[HACIdentifiers.server_address]
    }
    
    init(ip:String?, _ sessionToken:String?, _ authToken:String?,_ address:String?) {
        self.serverLocalIP = ip
        self.sessionToken = sessionToken
        self.authToken = authToken
        self.serverAddress = address
    }

    var toDictionary:[String:String]{
        return [HACIdentifiers.server_ip : serverLocalIP ?? "",
                HACIdentifiers.session_token : sessionToken ?? "",
                HACIdentifiers.auth_token : authToken ?? "",
                HACIdentifiers.server_address : serverAddress ?? ""]
    }
}
