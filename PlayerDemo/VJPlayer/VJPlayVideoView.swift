//
//  VJPlayVideoView.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/4.
//

import UIKit
import AVFoundation

open class VJPlayVideoView: UIView , UIGestureRecognizerDelegate{

    fileprivate var imageFrame  : CGRect! = nil

    private let displayHeight : CGFloat = 100    // VJSurfaceDisplay 整体视图所占的高度
    // MARK: UI
    // 视图顺序，自下而上
    // 蒙版
    fileprivate var backgroundView : UIView = {
        let aView = UIView(frame: UIScreen.main.bounds)
        aView.backgroundColor = UIColor.black
        aView.alpha = 1
        return aView
    }()
    // 视频播放器
    fileprivate var playerView  : VJPlayerView = {
        let aView = VJPlayerView(frame: UIScreen.main.bounds)
        aView.backgroundColor = UIColor.clear
        return aView
    }()
    // 手势视图
    fileprivate var gustureView : UIView = {
        let aView = UIView()
        aView.frame = UIScreen.main.bounds
        aView.backgroundColor = UIColor.clear
        return aView
    }()
    // 顶层按钮 overlayer
    fileprivate var surfaceDisplay : VJSurfaceDisplay = {
        let aView = VJSurfaceDisplay(frame: CGRect.zero)
        
        return aView
    }()
    
    fileprivate var callBack : ( _ index : Int)-> Void = {_ in}
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        self.isHidden = false
        setUpAssets()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        frame = UIScreen.main.bounds
        backgroundView.frame = bounds
        gustureView.frame = bounds
        surfaceDisplay.frame = CGRect(x: 0, y:bounds.height - displayHeight - UIWindow.safeBottom, width: bounds.width, height: displayHeight)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 初始化方法
    /// - Parameters:
    ///   - controller: 控制器
    ///   - view: 需要需要返回到的视图，点击处
    ///   - btns: 其他按钮的资源图片名称
    ///   - closure: 按钮点击回调
    convenience init(controller : UIViewController?,view : UIView?,btns: Array<String>,closure : @escaping (_ index : Int) -> Void) {
        self.init(frame: controller?.view.frame ?? UIScreen.main.bounds)
        let btnFrame = view?.superview?.convert(view!.frame, to: controller?.view)
        imageFrame = btnFrame
        controller?.view.addSubview(self)
        callBack = closure
        addSubview(backgroundView)
        addSubview(playerView)
        addSubview(gustureView)
        addSubview(surfaceDisplay)
        surfaceDisplay.imageStrings = btns
        surfaceDisplay.timeSlider.addTarget(self, action: #selector(timeSliderDidChange(_:)), for: .valueChanged)
        surfaceDisplay.playBtn.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        addGusture()
        setUpAssets()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChangeNotificationAction(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        if #available(iOS 13, *) {
            // 缺失iOS13以上监听屏幕旋转的方法
        } else {
        }
    }
    
    @objc func deviceOrientationDidChangeNotificationAction(_ noti: NSNotification) {
        if UIWindow.isLandscape() {
            playerView.frame = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
        } else {
            playerView.frame = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
        }
    }
    
    func addGusture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(respondsToPanGesture(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.maximumNumberOfTouches = 1
        gustureView.addGestureRecognizer(panGesture)
    }
    
    private func setUpAssets() {
        backgroundColor = UIColor.clear
        clipsToBounds = true
    }
    
    private static var originPoint : CGPoint!
    private static var  isPortrait : Bool = true // 手势向上
    @objc func respondsToPanGesture(_ pan:UIPanGestureRecognizer) {
        
        let point = pan.location(in: gustureView)
//        print("x = \(point.x),y = \(point.y)")
        if pan.state == .began {
            moveBegan(point)
        } else if pan.state == .changed {
            // 开始移动
            if VJPlayVideoView.originPoint != nil &&
                point.y >  VJPlayVideoView.originPoint.y {
                VJPlayVideoView.isPortrait = false
            }
            if !VJPlayVideoView.isPortrait {
                
                let offSetX : CGFloat = VJPlayVideoView.originPoint.x - point.x
                let offSetY : CGFloat = VJPlayVideoView.originPoint.y - point.y
//                print(offSetY)
                let proportion : Double = 1.0 - (abs(offSetY) / bounds.size.height) // 随着y轴变化  x轴不变
//                print("\(proportion)")
                playerView.bounds = CGRect(x: 0, y: 0, width:  bounds.size.width * proportion, height: bounds.size.height * proportion)
                let maxCenterY =  bounds.size.height -  playerView.bounds.size.height * 0.5
                let centerY = (center.y - offSetY) > maxCenterY ? maxCenterY :  (center.y - offSetY)
                playerView.center = CGPoint(x: center.x - offSetX, y: centerY)
//                print("修改前: width : \(bounds.size.width)  , height : \(bounds.size.height)")
//                print("修改后: width : \(playerView.bounds.size.width)  , height : \(playerView.bounds.size.height)")
                // 背景颜色
                backgroundView.alpha = proportion  > 0.3 ? proportion : 0.3
            }
//            print("changed")
        } else if pan.state == .cancelled || pan.state == .ended || pan.state == .recognized || pan.state == .failed {
            moveBegan(point) //  VJPlayVideoView.originPoint 可能为空
            let offSetY : CGFloat = VJPlayVideoView.originPoint.y - point.y
            let proportion : Double = 1.0 - (abs(offSetY) / bounds.size.height) // 随着y轴变化  x轴不变
            // 缩放比例大于0.9
            var isHiddenVideoView : Bool = proportion > 0.9
            // 结束时比开始点位高 还原
            if VJPlayVideoView.originPoint.y > point.y {
                isHiddenVideoView = true
            }
            // 比开始点位低 缩小
            UIView.animate(withDuration: 0.3) {
                if isHiddenVideoView {
                    self.playerView.frame = self.frame
                    self.surfaceDisplay.isHidden = false
                    self.backgroundView.alpha = 1
                }else {
                    print("缩小到视图中")
                    self.playerView.frame = self.imageFrame
                    VJPlayerEngine.pause()
                }
            } completion: { _ in
                VJPlayVideoView.originPoint = nil
                VJPlayVideoView.isPortrait = true
                if !isHiddenVideoView {
                    self.resourceRelease()
                }
            }
//            videoView.center = CGPoint(x: view.center.x, y: view.center.y)
            print("end")
        }
        
    }

    
    private func moveBegan(_ point : CGPoint) {
        if VJPlayVideoView.originPoint == nil {
            VJPlayVideoView.originPoint = point
            surfaceDisplay.isHidden = true
        }
    }
    
    /// 退出时释放资源
    private func resourceRelease() {

        VJPlayerEngine.exitPlayback()
        self.backgroundView.removeFromSuperview()
        self.gustureView.removeFromSuperview()
        self.playerView.removeFromSuperview()
        self.surfaceDisplay.resourceRelease()
        self.surfaceDisplay.removeFromSuperview()
        imageFrame = nil
        self.removeFromSuperview()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}


extension VJPlayVideoView {
    open func showVideo(_ url : URL) {
        VJPlayerEngine.showVideo(url) {[unowned self] playLayer in
            playerView.playerLayer = playLayer
            playerView.layer.addSublayer(playLayer)
            playerView.playerLayer?.bounds = self.bounds
            playerView.playerLayer?.videoGravity = .resizeAspect // 填充方式 充满屏幕  拉伸
        }
        // 设置初始时间
        VJPlayerEngine.sliderDisplaySetUp = {[unowned self] (_ enable:Bool,_ currentValue:Float,_ startText:String,_ maxValue:Float,_ durationText:String) in
            
            self.surfaceDisplay.isEnabled(enable)
            if enable {
                self.surfaceDisplay.timeSlider.value = currentValue
                self.surfaceDisplay.startTimeLabel.text = startText
                self.surfaceDisplay.timeSlider.maximumValue = maxValue
                self.surfaceDisplay.durationLabel.text = durationText
            }
        }
        // 时时更新时间状态
        VJPlayerEngine.sliderDisplay = {[unowned self] (_ currentValue : Float,_ startText : String) in
            
            self.surfaceDisplay.timeSlider.value = currentValue
            self.surfaceDisplay.startTimeLabel.text = startText
        }
        
        VJPlayerEngine.sliderPlayButtonImage = {[unowned self] (image : UIImage) in
            self.surfaceDisplay.playBtn.setImage(image, for: .normal)
        }
        
        surfaceDisplay.timeSlider.startDragging = {
           print("开始拖拽===================")
            VJPlayerEngine.removePeriodicTimeObserver()
        }
        
        surfaceDisplay.timeSlider.endDragging = {
            print("拖拽结束=====================")
            print("添加监听")
            VJPlayerEngine.addPeriodicTimeObserver()
//            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
//                DispatchQueue.main.async {
//                }
//            }
        }
        
    }
    
    @objc func togglePlay() {
        VJPlayerEngine.togglePlay()
    }
    
    @objc func timeSliderDidChange(_ sender : UISlider) {
        if let slider : VJSlider = sender as? VJSlider , slider.isDrag {
            let text = VJPlayerEngine.shared().createTimeString(time: slider.value)
            self.surfaceDisplay.startTimeLabel.text = text
        }
        VJPlayerEngine.sliderValueChanged(sender.value)
    }
    

}
