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

    private let displayHeight : CGFloat = 100   // 竖屏状态下 VJSurfaceDisplay 整体视图所占的高度
    private let displayLandscapeHeight : CGFloat = 44    // 横屏状态下 整体视图所占高度
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
        aView.backgroundColor = UIColor.clear
        return aView
    }()
    // 最中间的播放按钮
    fileprivate var playBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage.resource("play_large"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        btn.isHidden = true
        return btn
    }()
    fileprivate var isRemoveFromSuperView : Bool = false
    
    fileprivate var callBack : (( _ index : Int)-> Void)? = nil
    
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
        playBtn.center = center
        if !UIWindow.isLandscape() {
            surfaceDisplay.frame = CGRect(x: 0, y:bounds.height - displayHeight - UIWindow.safeBottom, width: bounds.width, height: displayHeight)
        } else {
            surfaceDisplay.frame = CGRect(x: 0, y:bounds.height - displayLandscapeHeight - UIWindow.safeBottom, width: bounds.width, height: displayLandscapeHeight)
        }
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
        addSubview(playBtn)
        surfaceDisplay.setButtonImage(btns)
        addBtnTarget()
        surfaceDisplay.timeSlider.addTarget(self, action: #selector(timeSliderDidChange(_:)), for: .valueChanged)
        surfaceDisplay.playBtn.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        surfaceDisplay.closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        playBtn.addTarget(self, action: #selector(playBtnAction(_:)), for: .touchUpInside)
        addGusture()
        setUpAssets()
        NotificationCenter.default.addObserver(self, selector: #selector(VJPlayVideoView.deviceOrientationDidChange) , name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChangeNotificationAction(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        if #available(iOS 13, *) {
            // 缺失iOS13以上监听屏幕旋转的方法
        } else {
        }
    }
    
    private func addBtnTarget() {
        surfaceDisplay.buttons.forEach { btn in
            btn.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        }
    }
    
    @objc func btnAction(_ buttton : UIButton ) {
        let index = buttton.tag - 2222
        print("点击了第\(index)按钮")
        if let call = callBack  {
            call(index)
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
                    if !VJPlayerEngine.currentlyPlaying() {
                        self.playBtn.isHidden = false
                    }
                    self.backgroundView.alpha = 1
                }else {
                    print("缩小到视图中")
                    self.isRemoveFromSuperView = true
                    self.playerView.frame = self.imageFrame
                    VJPlayerEngine.pause()
                }
            } completion: { _ in
                VJPlayVideoView.originPoint = nil
                VJPlayVideoView.isPortrait = true
                if !isHiddenVideoView {
                    self.resourceRelease()
                } else {
                    self.isRemoveFromSuperView = false
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
            self.playBtn.isHidden = true
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
        self.playBtn.removeFromSuperview()
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
        
        VJPlayerEngine.sliderPlayButtonImage = {[unowned self] (isPlay : Bool) in
            self.surfaceDisplay.refreshButtonImage(isPlay)
        }
        
        surfaceDisplay.timeSlider.startDragging = {[unowned self] in
           print("开始拖拽===================")
            VJPlayerEngine.removePeriodicTimeObserver()
            if !self.playBtn.isHidden { self.playBtn.isHidden = true }
        }
        
        surfaceDisplay.timeSlider.endDragging = {[unowned self] (slider : VJSlider) in
            if slider.isDrag { return }
            if !VJPlayerEngine.currentlyPlaying() {
                self.playBtn.isHidden = false
            }
            print("拖拽结束=====================")
            print("添加监听")
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.4) {
                DispatchQueue.main.async {
                    print("添加监听===================== async")
                    VJPlayerEngine.addPeriodicTimeObserver()
                    print("添加监听===================== 当前值\(slider.value)")

                }
            }
        }
        
        VJPlayerEngine.shared().playAction = {[unowned self] (play : Bool) in
            if isRemoveFromSuperView { return }
            self.playBtn.isHidden = play
        }
        
    }
    
    /// 播放暂停切换事件
    @objc func togglePlay() {
        VJPlayerEngine.togglePlay()
        let isPlaying = VJPlayerEngine.currentlyPlaying()
        surfaceDisplay.refreshButtonImage(isPlaying)
        playBtn.isHidden = isPlaying
    }
    
    @objc func closeAction() {

        UIView.animate(withDuration: 0.3) {
            print("缩小到视图中")
            self.playerView.frame = self.imageFrame
            VJPlayerEngine.pause()
        } completion: { _ in
            VJPlayVideoView.originPoint = nil
            VJPlayVideoView.isPortrait = true
            self.resourceRelease()

        }
    }
    
    ///  播放进度条拖拽事件
    @objc func timeSliderDidChange(_ sender : UISlider) {
        if let slider : VJSlider = sender as? VJSlider , slider.isDrag {
            let text = VJPlayerEngine.shared().createTimeString(time: slider.value)
            self.surfaceDisplay.startTimeLabel.text = text
        }
        VJPlayerEngine.sliderValueChanged(sender.value)
    }
    
    @objc func playBtnAction(_ button : UIButton) {
        togglePlay()
        button.isHidden = true
    }
}

// 用来记录这一次旋转到的状态，等旋转到最上面的时候可以计算清楚
private var orientationTemp  : AVCaptureVideoOrientation = .portrait

extension VJPlayVideoView {
    
    @objc fileprivate func deviceOrientationDidChange(){
        let orientation : UIDeviceOrientation = UIDevice.current.orientation

        // 方向旋转  对应的显示屏幕旋转 非录制输入屏幕方向
        if orientation.isPortrait || orientation.isLandscape
        {
            var videoOrientation : AVCaptureVideoOrientation = .portrait
            switch orientation {
            case .landscapeLeft:
                videoOrientation = .landscapeLeft
                if orientationTemp == .portraitUpsideDown {
                    layoutPlayerLayer()
                }
            case .landscapeRight:
                videoOrientation = .landscapeRight
                if orientationTemp == .portraitUpsideDown {
                    layoutPlayerLayer()
                }
            case .faceUp:
                videoOrientation = .portrait
            case .faceDown:
                videoOrientation = .portraitUpsideDown
            case .portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
            case .portrait:
                videoOrientation = .portrait
            case .unknown:
                videoOrientation = .portrait
            @unknown default:
                fatalError()
            }
//            playerLayer?.connection?.videoOrientation = videoOrientation
            orientationTemp = videoOrientation
        }
        
    }
    // 左右旋转到270度时，修正layer视图层大小
    private func layoutPlayerLayer() {
        playerView.frame = bounds
    }
    
}

