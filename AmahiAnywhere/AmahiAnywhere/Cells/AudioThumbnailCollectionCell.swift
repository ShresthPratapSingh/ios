//
//  AudioThumbnailCollectionCell.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 14/07/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import UIKit

class AudioThumbnailCollectionCell: UICollectionViewCell {
    
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.layer.masksToBounds = false
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = UIScreen.main.bounds.width * 0.04
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.height < self.bounds.width{
            leadingConstraint.isActive = false
            trailingConstraint.isActive = false
        }
        
        if self.bounds.width<self.bounds.height
        {
            topConstraint.isActive = false
            bottomConstraint.isActive = false
        }
    }
    
    override func prepareForReuse() {
        imageView.image = UIImage(named: "musicPlayerArtWork")
    }

}
