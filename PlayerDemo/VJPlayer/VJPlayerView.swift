//
//  VJPlayerView.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/19.
//

import UIKit
import AVFoundation

internal class VJPlayerView: UIView {

    var playerLayer  : AVPlayerLayer? 

    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

