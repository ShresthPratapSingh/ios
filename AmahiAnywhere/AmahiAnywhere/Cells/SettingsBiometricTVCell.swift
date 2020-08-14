//
//  SettingsBiometricTVCellTableViewCell.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 13/08/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import UIKit

class SettingsBiometricTVCell: UITableViewCell {

    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var titleLabel:UILabel!
    weak var delegate: SettingsViewController?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func toggleAction(_ sender: Any) {
        if toggleSwitch.isOn{
            delegate?.turnOnBiometric()
        }else{
            delegate?.turnOffBiometric()
        }
    }
    
}
