//
//  SettingsViewController+TableViewDataSource.swift
//  AmahiAnywhere
//
//  Created by Kanyinsola Fapohunda on 03/04/2019.
//  Copyright © 2019 Amahi. All rights reserved.
//

import Foundation

extension SettingsViewController {
    
    // MARK: - Table View data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return titleForSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        var cell: UITableViewCell
        
        if section == 1{
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.settingsCellWithDetails, for: indexPath)
            cell.textLabel?.text = settingItems[section][row]
            formatCell(cell: &cell)
    
            if row == 0 {
                let connectionMode = LocalStorage.shared.userConnectionPreference
                
                if connectionMode == ConnectionMode.auto {
                    let isLocalInUse = ConnectionModeManager.shared.isLocalInUse()
                    
                    if isLocalInUse {
                        cell.detailTextLabel?.text =  StringLiterals.autoConnectLAN
                    } else {
                        cell.detailTextLabel?.text =  StringLiterals.autoConnectRemote
                    }
                } else {
                    cell.detailTextLabel?.text =  LocalStorage.shared.userConnectionPreference.rawValue
                }
            }else if row == 1 {
                let cacheFolderPath = FileManager.default.temporaryDirectory.appendingPathComponent("cache").path
                let cacheSize = FileManager.default.folderSizeAtPath(path: cacheFolderPath)
                var sizeString = String(format: StringLiterals.currentSize, ByteCountFormatter().string(fromByteCount: cacheSize))
                if let freeSpaceBytes = getFreeSize(){
                    let freeSpaceString = Units(bytes: freeSpaceBytes).getReadableUnit()
                    sizeString.append(contentsOf: "\t•\tAvailable space: \(freeSpaceString)")
                }
                cell.detailTextLabel?.text = sizeString
            }
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            return cell
        }else if section == 2 {
            if row == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.settingsCellRightDetail, for: indexPath)
                cell.textLabel?.text = settingItems[section][row]
                formatCell(cell: &cell)
                if let versionNumber = Bundle.main.object(forInfoDictionaryKey: StringLiterals.versionNumberDictionaryKey) as! String? {
                    cell.detailTextLabel?.text = "v\(versionNumber)"
                }
                cell.backgroundColor = .clear
                cell.contentView.backgroundColor = .clear
                return cell
            }
            else if row == 1{
                cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.settingsCell, for: indexPath)
                cell.textLabel?.text = settingItems[section][row]
                formatCell(cell: &cell)
                cell.backgroundColor = .clear
                cell.contentView.backgroundColor = .clear
                return cell
            }else{
                return UITableViewCell()
            }
        }else if section == 0{
            if row == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.settingsCell, for: indexPath)
                cell.textLabel?.text = settingItems[section][row]
                formatCell(cell: &cell)
                return cell
            }else if row == 1{
                guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.biometricCell) as? SettingsBiometricTVCell else{
                    return UITableViewCell()
                }
                cell.titleLabel?.text = settingItems[section][row]
                cell.delegate = self
                cell.toggleSwitch.setOn(LocalStorage.shared.getBool(for: PersistenceIdentifiers.biometricEnabled), animated: false)
                return cell
            }else{
                return UITableViewCell()
            }
        }else{
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func formatCell(cell: inout UITableViewCell){
        
        if #available(iOS 13.0, *) {
            cell.textLabel?.textColor = UIColor.label

            cell.detailTextLabel?.textColor = UIColor.label
        } else {
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = #colorLiteral(red: 0.8055401332, green: 0.8055401332, blue: 0.8055401332, alpha: 1)
        }
       
        let selectedBackgroundView = UIView()
        if #available(iOS 13.0, *) {
            selectedBackgroundView.backgroundColor = UIColor.secondarySystemBackground

        } else {
            selectedBackgroundView.backgroundColor = UIColor(named: "formal")
        }
        
        cell.selectedBackgroundView = selectedBackgroundView
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()

        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
            
        } else {
            view.backgroundColor = UIColor(named: "131517")


        }
        
        let label = UILabel()
        view.addSubview(label)
        label.text = titleForSections[section]
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .white
        }
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.setAnchors(top: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: nil, topConstant: nil, leadingConstant: 12, trailingConstant: 20, bottomConstant: nil)
        label.center(toVertically: view, toHorizontally: nil)
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    
}
