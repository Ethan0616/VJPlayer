//
//  VJSurfaceDisplay.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/19.
//

import UIKit

class VJSurfaceDisplay: UIView {
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
    private let playWidth    : CGFloat = 44      // 播放按钮宽度
    private let playRightSpace : CGFloat = 10    // 播放按钮右边空间
    private let labelWidth   : CGFloat = 60      // 时间显示的宽度
    private let toolViewHeight : CGFloat = 50    // toolBar 高度
    
    var playBtn : UIButton! = {
        let btn = UIButton(type: .custom)
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "play.fill"), for: .highlighted)
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        } else {
            // Fallback on earlier versions
        }
        btn.sizeToFit()
        return btn
    }()
    
    var timeSlider : UISlider! = {
        let slider  = UISlider()
        slider.value = 0
        return slider
    }()
    var startTimeLabel : UILabel! = {
      let label = UILabel()
        label.backgroundColor = UIColor.gray
        label.textAlignment = .right
        return label
    }()
    var durationLabel : UILabel! = {
        let label = UILabel()
        label.backgroundColor = UIColor.gray
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
        playBtn.frame = CGRect(x: playLeftSpace, y: bounds.size.height - bottomHeight, width: playWidth, height: 44)
        startTimeLabel.frame = CGRect(x: playBtn.frame.origin.x + playBtn.frame.size.width + playRightSpace, y: bounds.size.height - bottomHeight , width: labelWidth, height: 44)
        let timeSliderWidth : CGFloat =  bounds.size.width - (playLeftSpace * 2 + playRightSpace + playWidth  + labelWidth * 2 + 10)
        let timeSliderLeft : CGFloat = playLeftSpace + playWidth + playRightSpace + labelWidth + 5
        timeSlider.frame = CGRect(x: timeSliderLeft, y: bounds.size.height - bottomHeight , width: timeSliderWidth, height: 44)
        durationLabel.frame = CGRect(x: timeSlider.frame.origin.x + timeSlider.frame.size.width + 5, y: bounds.size.height - bottomHeight, width: labelWidth, height: 44)
    }
    
    
    @objc func btnAction(_ sender:UIButton) {
        
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
