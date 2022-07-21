//
//  CustomTableViewCell.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/4.
//

import UIKit

@objc
protocol CustomTableViewCellProtocol : NSObjectProtocol {
    func imageClicked(_ frame: CGRect) ->URL
}

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var imageBtn: UIButton!
    weak var delegate : CustomTableViewCellProtocol?
    // 显示的视图
    weak var controller : UIViewController?

//    // 核心代码 视频播放器懒加载
//    lazy var videoView : VJPlayVideoView! = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // test
    convenience override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)

    }
    
    convenience init(style: UITableViewCell.CellStyle, reuseIdentifier: String? ,backgroundView : UIView?) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    @IBAction func imageBtnAction(_ sender: Any) {
        // 这部分只是用于演示，当在controller中调用时，需要自定义代理，把URL传入SDK
        let btnFrame = self.convert(self.imageBtn.frame, to: controller?.view)
        if let urlPath = delegate?.imageClicked(btnFrame) {
            let videoView = VJPlayVideoView(controller: controller, view: imageBtn, btns: ["123"]) { index in
                print(index)
            }
            // 唤起页面 核心代码
            videoView.showVideo(urlPath)
        }
    }
}
