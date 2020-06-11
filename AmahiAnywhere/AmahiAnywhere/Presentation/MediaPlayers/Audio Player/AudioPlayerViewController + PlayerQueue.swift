//
//  AudioPlayerViewController + QueueLayout.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 07/06/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import UIKit
import AVFoundation

extension AudioPlayerViewController: AudioPlayerQueueDelegate {
    
    func layoutPlayerQueue(){
        self.view.addSubview(playerQueueContainer)
        self.view.bringSubviewToFront(playerQueueContainer)
        self.view.bringSubviewToFront(queueHeader)
                
        queueBottomConstraintForOpen = self.queueHeader.bottomAnchor.constraint(equalTo:self.view.bottomAnchor, constant: -queueVCHeight)
        queueBottomConstraintForCollapse = self.queueHeader.bottomAnchor.constraint(equalTo:self.view.bottomAnchor, constant: 0)
        
        queueBottomConstraintForCollapse?.isActive = true
        queueBottomConstraintForOpen?.isActive = false
        
        queueHeader.heightAnchor.constraint(equalToConstant: 65).isActive = true
        
        playerQueueContainer.translatesAutoresizingMaskIntoConstraints = false
        playerQueueContainer.topAnchor.constraint(equalTo:queueHeader.topAnchor, constant: 0).isActive = true
        playerQueueContainer.leadingAnchor.constraint(equalTo:self.view.leadingAnchor, constant: 0).isActive = true
        playerQueueContainer.trailingAnchor.constraint(equalTo:self.view.trailingAnchor,constant: 0).isActive = true
        playerQueueContainer.heightAnchor.constraint(equalToConstant: queueVCHeight + 65).isActive = true
    }
    
    
    //MARK:- Delegate methods
    
    func didDeleteItem(at indexPath: IndexPath) {
        if let queueVC = self.children.first as? AudioPlayerQueueViewController, playerItems[indexPath.row] == queueVC.currentPlayerItem{
            playNextSong()
        }
        playerItems.remove(at: indexPath.row)
    }
    
    func didMoveItem(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let item = playerItems?[sourceIndexPath.row]{
            playerItems?.insert(item, at: destinationIndexPath.row)
        }
    }
    
    func shouldPlay(item: AVPlayerItem, at indexPath: IndexPath) {
        player.replaceCurrentItem(with: item)
        loadSong()
    }
    
}
