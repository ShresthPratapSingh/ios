//
//  AudioPlayerViewController+Gesture.swift
//  AmahiAnywhere
//
//  Created by Marton Zeisler on 2019. 08. 10..
//  Copyright © 2019. Amahi. All rights reserved.
//

import UIKit

extension AudioPlayerViewController{
    
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .began:
            startInteractiveTransition(state:nextState,duration: 1)
        case .changed:
            let yTranslation = sender.translation(in: self.playerQueueContainer).y
            var fractionComplete = yTranslation/self.queueVCHeight
            fractionComplete = currentQueueState == .collapsed ? -fractionComplete : fractionComplete
            print("\n\n$$$$$$$\nupdateTransition fractionComplete = \(fractionComplete)")
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
            print("\n\n@@@@@@@ animationProgressWhenInterrupted = \(animationProgressWhenInterrupted)")
        }
    }
    
    func animateIfNeeded(state:QueueState,duration:TimeInterval){
        if interactiveAnimators.isEmpty{
            let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state{
                case .collapsed:
                    self.queueBottomConstraintForCollapse?.isActive = true
                    self.queueBottomConstraintForOpen?.isActive = false
                    self.queueHeader.alpha = 1
                    self.queueHeaderArrow.transform = self.queueHeaderArrow.transform.rotated(by: CGFloat.pi)
                case .open:
                    self.queueBottomConstraintForCollapse?.isActive = false
                    self.queueBottomConstraintForOpen?.isActive = true
                    self.queueHeader.alpha = 0
                    self.queueHeaderArrow.transform = self.queueHeaderArrow.transform.rotated(by: CGFloat.pi)
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
    
   @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            animateIfNeeded(state: nextState, duration: 1)
        default:
            break
        }
    }
}
