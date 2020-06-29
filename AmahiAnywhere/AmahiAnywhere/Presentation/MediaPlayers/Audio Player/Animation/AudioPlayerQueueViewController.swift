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
        }
    }
    var currentPlayerItem:AVPlayerItem?
    var trackNames = [AVPlayerItem: String]()
    var artistNames = [AVPlayerItem: String]()
    var thumbnailImages = [AVPlayerItem:UIImage]()
    var shuffledArray: [Int]?
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
        var count = 0
        if queuedItems != nil{
            count = queuedItems!.count - 1
        }
        shuffledArray = Array((0...count).lazy)
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
        
        if let index = shuffledArray?[indexPath.row]{
            track = queuedItems?[index]
        }else{
            track = queuedItems?[indexPath.row]
        }
        if track != nil{
            cell.titleLabel.text = trackNames[track!] ?? "Title"
            cell.artistLabel.text = artistNames[track!] ?? "Artist"
            cell.thumbnailView.image = thumbnailImages[track!] ?? UIImage(named:"musicPlayerArtWork")
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
        }
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let newTrack = queuedItems?[indexPath.row]{
            delegate?.shouldPlay(item: newTrack, at: indexPath)
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
