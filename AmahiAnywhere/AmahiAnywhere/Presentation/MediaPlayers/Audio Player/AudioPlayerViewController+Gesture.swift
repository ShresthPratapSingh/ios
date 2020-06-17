//
//  AudioPlayerViewController+Gesture.swift
//  AmahiAnywhere
//
//  Created by Marton Zeisler on 2019. 08. 10..
//  Copyright © 2019. Amahi. All rights reserved.
//

import UIKit

extension AudioPlayerViewController{
    
   @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
    
        switch sender.state {
        case .began:
            startInteractiveTransition(state:nextState,duration: 0.7)
        case .changed:
            let yTranslation = sender.translation(in: self.playerQueueContainer).y
            var fractionComplete = yTranslation/self.queueVCHeight
            fractionComplete = currentQueueState == .collapsed ? -fractionComplete : fractionComplete
            updateInteractiveTransition(fractionCompleted:fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func startInteractiveTransition(state:QueueState,duration: TimeInterval){
        if interactiveAnimators.isEmpty{
            animateIfNeeded(state: state, duration: duration)
        }
        for animator in interactiveAnimators{
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func animateIfNeeded(state:QueueState,duration:TimeInterval){
        if interactiveAnimators.isEmpty{
            let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.7) {
                switch state{
                case .collapsed:
                    self.queueTopConstraintForCollapse?.isActive = true
                    self.queueTopConstraintForOpen?.isActive = false
                    self.playerQueueContainer.header.alpha = 1
                    self.playerQueueContainer.header.arrowHead.transform = self.playerQueueContainer.header.arrowHead.transform.rotated(by: CGFloat.pi)
                case .open:
                    self.queueTopConstraintForCollapse?.isActive = false
                    self.queueTopConstraintForOpen?.isActive = true
                    self.playerQueueContainer.header.alpha = 1
                    self.playerQueueContainer.header.arrowHead.transform = self.playerQueueContainer.header.arrowHead.transform.rotated(by: CGFloat.pi)
                }
                
                self.view.layoutIfNeeded()
            }
            
            animator.addCompletion { (_) in
                self.interactiveAnimators.removeAll()
                self.currentQueueState = state
            }
            
            animator.startAnimation()
            interactiveAnimators.append(animator)
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat){
        for animator in interactiveAnimators{
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition(){
        for animator in interactiveAnimators{
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
   @objc func handleArrowHeadTap() {
        animateIfNeeded(state: nextState, duration: 0.7)
    }
}
