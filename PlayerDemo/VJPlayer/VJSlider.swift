//
//  VJSlider.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/22.
//

import UIKit

class VJSlider: UISlider {

    var isDrag : Bool = false
    
    var startDragging : (()->Void)? = nil
    var endDragging : ((VJSlider)->Void)? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        // 点击点
        let touchPoint : CGPoint = touch.location(in: self)
        // 滑块rect
        let thumImageRect = self.thumbRect(forBounds: self.bounds, trackRect: self.bounds, value: self.value)
        // 坐标系转换到slider
        let rect = self.convert(thumImageRect, to: self)
        // 是否为滑块触摸的地方
        let isContain : Bool = rect.contains(touchPoint)
        
        if isContain {
//            print("开始拖拽")
            isDrag = true
            if let event = startDragging {
                event()
            }
        } else {
//            print("点击区域超出范围")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if isDrag {
            isDrag = false
            if let event = endDragging {
                event(self)
            }
//            print("拖拽结束")
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
