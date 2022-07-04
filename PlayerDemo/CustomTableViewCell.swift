//
//  CustomTableViewCell.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/4.
//

import UIKit

@objc
protocol CustomTableViewCellProtocol : NSObjectProtocol {
    func imageClicked(_ frame : CGRect)
}

class CustomTableViewCell: UITableViewCell {

    lazy var videoView : VJPlayVideoView! = {
        let videoView = VJPlayVideoView(frame: UIScreen.main.bounds)
        videoView.isHidden = true
        return videoView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    convenience init(style: UITableViewCell.CellStyle, reuseIdentifier: String? ,vc : CustomTableViewCellProtocol,btns: Array<String>) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    @IBAction func imageBtnAction(_ sender: Any) {
        // 唤起页面
        
        print("ViewController delegate")
        videoView.isHidden = !videoView.isHidden
        let path : String = Bundle.main.path(forResource: "1653903243735430", ofType: "mp4") ?? ""
        let urlPath = URL.init(fileURLWithPath: path)
        videoView.playVideo(urlPath)
//        imageFrame = frame
//        let urlPath =  URL.init(string: "http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4")
//        videoView.playVideo(urlPath!)
        
    }
}
