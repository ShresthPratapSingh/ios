//
//  TimeStamp.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 30/06/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import Foundation

class TimeStamp {
    
    func getCurrentTimeStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: Date())
    }
}
