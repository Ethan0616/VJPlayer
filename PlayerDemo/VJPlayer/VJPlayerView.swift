//
//  VJPlayerView.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/19.
//

import UIKit
import AVFoundation

class VJPlayerView: UIView {

    var playerLayer  : AVPlayerLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = self.bounds
    }
    
    
    @objc func playVideo(_ player : AVPlayer){
        removePlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect // 填充方式 充满屏幕  拉伸
        playerLayer.frame = self.bounds
        layer.addSublayer(playerLayer)
    }
    
    func removePlayer(){
        if playerLayer != nil {
            playerLayer.player?.pause()
            playerLayer.removeAllAnimations()
            playerLayer.removeFromSuperlayer()
            playerLayer = nil
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

