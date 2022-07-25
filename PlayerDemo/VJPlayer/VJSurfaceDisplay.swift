//
//  VJSurfaceDisplay.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/19.
//

import UIKit

internal class VJSurfaceDisplay: UIView {
    // Public
    public func isEnabled(_ enable:Bool) {
        playBtn.isEnabled = enable
        timeSlider.isEnabled = enable
        startTimeLabel.isEnabled = enable
        durationLabel.isEnabled = enable
    }
    
    // MARK: layout
    private let bottomHeight : CGFloat = 100     // 距离底边距离
    private let playLeftSpace: CGFloat = 20      // 播放按钮左侧空间
    private let playWidth    : CGFloat = 25      // 播放按钮宽度
    private let closeWidth    : CGFloat = 30      // 关闭按钮宽度
    private let playRightSpace : CGFloat = 10    // 播放按钮右边空间
    private let labelWidth   : CGFloat = 60      // 时间显示的宽度
    private let toolViewHeight : CGFloat = 50    // toolBar 高度
    
    var playBtn : UIButton! = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage.resource("pause", Dir: nil), for: .normal)
        btn.sizeToFit()
        btn.clipsToBounds = true
        return btn
    }()
    
    var closeBtn : UIButton! = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage.resource("close", Dir: nil), for: .normal)
        btn.sizeToFit()
        btn.clipsToBounds = true
        return btn
    }()
    
    var timeSlider : VJSlider! = {
        let slider  = VJSlider()
        slider.value = 0
//        slider.setThumbImage(UIImage.init(named: "image"), for: .normal) // 报错注释调这行
        slider.backgroundColor = UIColor.clear
        slider.thumbTintColor = UIColor.white
        slider.minimumTrackTintColor = UIColor.white // 进度条颜色
//        slider.maximumTrackTintColor = UIColor.lightGray // 进度条底色
//        slider.isContinuous = false    // 拖拽结束时刻响应didchange事件
        
        return slider
    }()
    var startTimeLabel : UILabel! = {
      let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .right
        return label
    }()
    var durationLabel : UILabel! = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .left
          return label
    }()
    
    var buttons : Array<UIButton>? = nil
    var imageStrings : Array<String>? {
        didSet(newValue) {
            guard let imageNames = newValue  else {
                return
            }
            for i in 0..<imageNames.count {
                let str = imageNames[i]
                let btn = UIButton(type: .custom)
                btn.setImage(UIImage.init(named: str), for: .normal)
                btn.setImage(UIImage.init(named: str), for: .highlighted)
                btn.tag = 2222 + i
                btn.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
                addSubview(btn)
                buttons?.append(btn)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        addSubview(timeSlider)
        addSubview(startTimeLabel)
        addSubview(durationLabel)
        addSubview(playBtn)
        addSubview(closeBtn)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIWindow.isBangsScreen() {
            print("留海屏")
            print(UIWindow.safeBottom)
        } else {
            print("非留海屏幕")
            print(UIWindow.safeBottom)
        }
        if UIWindow.isLandscape() {
            print("横屏--------")
        } else {
            print("竖屏")
        }
        playBtn.frame = CGRect(x: playLeftSpace, y: bounds.size.height - bottomHeight + (44 - playWidth) * 0.5, width: playWidth, height: playWidth)
        closeBtn.frame = CGRect(x: playLeftSpace, y: bounds.size.height - closeWidth - (44 - closeWidth) * 0.5, width: closeWidth, height: closeWidth)
        closeBtn.center = CGPoint(x: playBtn.center.x, y: closeBtn.frame.origin.y + closeWidth * 0.5)
        startTimeLabel.frame = CGRect(x: playBtn.frame.origin.x + playBtn.frame.size.width + playRightSpace, y: bounds.size.height - bottomHeight , width: labelWidth, height: 44)
        let timeSliderWidth : CGFloat =  bounds.size.width - (playLeftSpace * 2 + playRightSpace + playWidth  + labelWidth * 2 + 10)
        let timeSliderLeft : CGFloat = playLeftSpace + playWidth + playRightSpace + labelWidth + 5
        timeSlider.frame = CGRect(x: timeSliderLeft, y: bounds.size.height - bottomHeight , width: timeSliderWidth, height: 44)
        durationLabel.frame = CGRect(x: timeSlider.frame.origin.x + timeSlider.frame.size.width + 5, y: bounds.size.height - bottomHeight, width: labelWidth, height: 44)
    }
    
    func resourceRelease() {
        buttons?.forEach{$0.removeFromSuperview()}
        buttons?.removeAll()
    }
    
    deinit {
        
    }
    
    @objc func btnAction(_ sender:UIButton) {
        
    }
    
    func refreshButtonImage(_ playing: Bool) {
        if playing {
            playBtn.setImage(UIImage.resource("pause", Dir: nil), for: .normal)
        } else {
            playBtn.setImage(UIImage.resource("play", Dir: nil), for: .normal)
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

//public extension UISlider {
//    
//    static var isDrag : Bool = false
//    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        guard let touch = touches.first else { return }
//        // 点击点
//        let touchPoint : CGPoint = touch.location(in: self)
//        // 滑块rect
//        let thumImageRect = self.thumbRect(forBounds: self.bounds, trackRect: self.bounds, value: self.value)
//        // 坐标系转换到slider
//        let rect = self.convert(thumImageRect, to: self)
//        // 是否为滑块触摸的地方
//        let isContain : Bool = rect.contains(touchPoint)
//        
//        if isContain {
////            print("开始拖拽")
//            UISlider.isDrag = true
//        } else {
////            print("点击区域超出范围")
//        }
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        if UISlider.isDrag {
//            UISlider.isDrag = false
////            print("拖拽结束")
//        }
//    }
//}
