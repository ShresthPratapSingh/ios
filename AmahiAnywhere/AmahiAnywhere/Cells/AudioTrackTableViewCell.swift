//
//  AudioTrackTableViewCell.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 10/06/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import UIKit

class AudioTrackTableViewCell:UITableViewCell{
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        thumbnailView.image = UIImage(named:"musicPlayerArtWork")
        titleLabel.text = "Title"
        artistLabel.text = "Artist"
    }
}
