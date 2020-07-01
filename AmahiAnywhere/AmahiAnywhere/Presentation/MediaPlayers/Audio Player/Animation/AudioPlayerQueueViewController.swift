//
//  AudioPlayerQueueViewController.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 07/06/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioPlayerQueueDelegate {
    func didDeleteItem(at indexPath:IndexPath)
    func didMoveItem(from sourceIndexPath:IndexPath, to destinationIndexPath: IndexPath)
    func shouldPlay(item:AVPlayerItem,at indexPath:IndexPath)
}

class AudioPlayerQueueViewController:UIViewController{
    
    let cellID = "trackCell"
    
    var queuedItems:[AVPlayerItem]?{
        didSet{
            setupQueueMetadata()
            var count = 0
            if queuedItems != nil{
                count = queuedItems!.count - 1
            }
            shuffledArray = Array((0...count).lazy)
        }
    }
    var currentPlayerItem:AVPlayerItem?
    var currentPlayerIndex:IndexPath?
    var trackNames = [AVPlayerItem: String]()
    var artistNames = [AVPlayerItem: String]()
    var thumbnailImages = [AVPlayerItem:UIImage]()
    var shuffledArray = [Int]()
    var itemURLs: [URL]?
    var delegate:AudioPlayerQueueDelegate?

    lazy var tableView:UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.register(UINib(nibName: "QueueItemTableViewCell", bundle: nil), forCellReuseIdentifier: cellID)
        return tableView
    }()
    
    //MARK:- VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }
    
    func setupQueueMetadata(){
        for item in queuedItems ?? []{
            let metaData = item.asset.metadata
            
            //extracting title
            let titleMetaData = AVMetadataItem.metadataItems(from: metaData, filteredByIdentifier: .commonIdentifierTitle)
            if let title = titleMetaData.first, let titleString = title.value as? String{
                trackNames[item] = titleString
            }
            
            //extracting artist
            let artistMetaData = AVMetadataItem.metadataItems(from: metaData, filteredByIdentifier: .commonIdentifierArtist)
            if let artist = artistMetaData.first, let artistString = artist.value as? String{
                artistNames[item] = artistString
            }
            
            //extracting thumbnail
            let imageMetaData = AVMetadataItem.metadataItems(from: metaData, filteredByIdentifier: .commonIdentifierArtwork)
            if let imageData = imageMetaData.first?.dataValue, let image = UIImage(data: imageData){
                thumbnailImages[item] = image
            }
        }
    }
    
    func updateCurrentSong(item newItem:AVPlayerItem){
        
        if let cell = tableView.cellForRow(at: currentPlayerIndex!) as? QueueItemTableViewCell{
            cell.stopPlayAnimation()
        }
        
        currentPlayerItem = newItem
        for (index,item) in (queuedItems ?? []).enumerated(){
            if item == newItem{
                currentPlayerItem = item
                currentPlayerIndex = IndexPath(row: shuffledArray[index] , section: 0)
                
                if let cell = tableView.cellForRow(at: currentPlayerIndex!) as? QueueItemTableViewCell{
                    cell.animatePlaying()
                }
                return
            }
        }
    }

    
}

//MARK:- TableView Delegate And DataSource

extension AudioPlayerQueueViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queuedItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? QueueItemTableViewCell else {
            return UITableViewCell()
        }
        
        var track:AVPlayerItem?
        
        if let index = queuedItems?.count, indexPath.row <= index{
            track = queuedItems?[shuffledArray[indexPath.row]]
        }
        
        if track != nil{
            cell.titleLabel.text = trackNames[track!] ?? "Title"
            cell.artistLabel.text = artistNames[track!] ?? "Artist"
            cell.thumbnailView.image = thumbnailImages[track!] ?? UIImage(named:"musicPlayerArtWork")
            cell.stopPlayAnimation()
            
            if track == currentPlayerItem{
                currentPlayerIndex = indexPath
                cell.animatePlaying()
            }
        }
        
        cell.thumbnailView.layer.cornerRadius = 5
        cell.thumbnailView.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Remove") { (acion, indexPath) in
            self.queuedItems?.remove(at: indexPath.row)
            self.delegate?.didDeleteItem(at: indexPath)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.reloadData()
        }
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let newTrack = queuedItems?[indexPath.row]{
            delegate?.shouldPlay(item: newTrack, at: indexPath)
            updateCurrentSong(item: newTrack)
        }else{
            let alert = UIAlertController(title: "Oops! coud not load track", message: nil, preferredStyle: .alert)
            present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let item = queuedItems?[sourceIndexPath.row]{
            if item == currentPlayerItem{
                updateCurrentSong(item: item)
                currentPlayerIndex = destinationIndexPath
            }
            queuedItems?.insert(item, at: destinationIndexPath.row)
            delegate?.didMoveItem(from: sourceIndexPath, to: destinationIndexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch UIDevice().userInterfaceIdiom {
        case .tv,.pad:
            return 100
        default:
            return 65
        }
    }
    
}
