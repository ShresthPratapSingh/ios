//
//  AudioPlayerViewController+CollectionView.swift
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 14/07/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

import Foundation

extension AudioPlayerViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModel.collectionViewDS.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: thumbnailCellID, for: indexPath) as? AudioThumbnailCollectionCell else {
            return UICollectionViewCell()
        }
        if indexPath.item < dataModel.collectionViewDS.count, let image = dataModel.thumbnailImages[dataModel.collectionViewDS[indexPath.item]]{
            cell.imageView.image = image
        }else{
            cell.imageView.image = UIImage(named:"musicPlayerArtWork")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee = scrollView.contentOffset
        let itemWidth = thumbnailCollectionView.bounds.width
        let proportionalOffset = scrollView.contentOffset.x / itemWidth
        swipe(for: proportionalOffset, with: velocity)
    }
    
    func swipe(for offset: CGFloat, with velocity: CGPoint){
        let wholeNumber = Int(offset)
        
        let drag = offset - CGFloat(wholeNumber)
        
        if (drag >= 0.20 || drag <= 0.20){
            if velocity.x < 0{
                playPreviousSong()
            }else{
                playNextSong()
            }
        }
        thumbnailCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func updateThumbnailCollectionView(for operation : MusicOperation){
        switch operation {
            case .previous:
                thumbnailCollectionView.performBatchUpdates({
                    if let item = dataModel.currentPlayerItem{
                        self.dataModel.collectionViewDS.insert(item, at: 0)
                        self.thumbnailCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
                    }
                }, completion: nil)
            case .next:
                dataModel.collectionViewDS.remove(at: 0)
                thumbnailCollectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
        }
    }
}

enum MusicOperation{
    case previous
    case next
}
