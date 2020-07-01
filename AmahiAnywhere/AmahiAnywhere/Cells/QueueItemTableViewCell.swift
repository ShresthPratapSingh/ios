//
//  QueueItemTableViewCell.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 29/06/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import UIKit

class QueueItemTableViewCell:UITableViewCell{
    
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var nowPlayingView: UIImageView!
    
    override func prepareForReuse() {
        thumbnailView.image = UIImage(named:"musicPlayerArtWork")
        titleLabel.text = "Title"
        artistLabel.text = "Artist"
        stopPlayAnimation()
    }
    
    func animatePlaying(){
        UIView.animate(withDuration: 0.7, delay: 0, options: [.repeat,.autoreverse], animations: {
            self.nowPlayingView.alpha = 1
        }, completion: nil)
    }
    
    func stopPlayAnimation(){
        UIView.animate(withDuration: 0.7, animations: {
            self.nowPlayingView.alpha = 0
        }) { (isComplete) in
            if isComplete{
                self.nowPlayingView.layer.removeAllAnimations()
            }
        }
    }
}
