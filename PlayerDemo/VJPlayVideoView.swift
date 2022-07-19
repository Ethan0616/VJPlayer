//
//  VJPlayVideoView.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/4.
//

import UIKit
import AVFoundation

class VJPlayVideoView: UIView , UIGestureRecognizerDelegate{

    fileprivate var imageFrame  : CGRect! = nil
    fileprivate var player      : AVPlayer!
    fileprivate var playerItem  : AVPlayerItem!
    fileprivate var url         : URL!

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
    
    // MARK: Properties
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    
    private var timeObserverToken: Any?
    private var playerItemStatusObserver: NSKeyValueObservation?
//    private var playerItemFastForwardObserver: NSKeyValueObservation?
//    private var playerItemReverseObserver: NSKeyValueObservation?
//    private var playerItemFastReverseObserver: NSKeyValueObservation?
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    
    static let pauseButtonImageName = "PauseButton"
    static let playButtonImageName = "PlayButton"
    
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        self.isHidden = false
        setUpAssets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        frame = UIScreen.main.bounds
        backgroundView.frame = bounds
        gustureView.frame = bounds
        surfaceDisplay.frame = CGRect(x: 0, y:bounds.height - displayHeight - UIWindow.safeBottom, width: bounds.width, height: displayHeight)
    }
    
    deinit {
        playerView.removePlayer()
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
        // 设置静音模式下播放
        let avSession = AVAudioSession.sharedInstance()
        try! avSession.setCategory(.playback)
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
            if point.y >  VJPlayVideoView.originPoint.y {
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
                    self.playerView.playerLayer.player?.pause()
                }
            } completion: { _ in
                VJPlayVideoView.originPoint = nil
                VJPlayVideoView.isPortrait = true
                if !isHiddenVideoView {
                    self.removeAllValues()
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
    
    private func removeAllValues() {

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        self.playerView.removePlayer() // 暂停播放 释放资源
        self.playerView.removeFromSuperview()
        self.gustureView.removeFromSuperview()
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
    func showVideo(_ url : URL) {
        playerItem  = AVPlayerItem(url: url )
        player = AVPlayer(playerItem: playerItem)
        playerView.playVideo(player)
        let asset = AVURLAsset(url: url)
        loadPropertyValues(forAsset: asset)
    }
    
    @objc
    func togglePlay() {
        
        switch player.timeControlStatus {
        case .playing:
            player.pause()
        case .paused:
            let currentItem = player.currentItem
            if currentItem?.currentTime() == currentItem?.duration {
                currentItem?.seek(to: .zero, completionHandler: { finsh in
                    
                })
            }
            player.play()
        default:
            player.pause()
        }
    }
    
    @objc
    func timeSliderDidChange(_ sender : UISlider) {
        
        let newTime = CMTime(seconds: Double(sender.value), preferredTimescale: 600)

        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}




extension VJPlayVideoView {
    // MARK: - Asset Property Handling
    func loadPropertyValues(forAsset newAsset: AVURLAsset) {
        
        let assetKeysRequiredToPlay = [
            "playable",
            "hasProtectedContent"
        ]
        
        newAsset.loadValuesAsynchronously(forKeys: assetKeysRequiredToPlay) {

            DispatchQueue.main.async {
                

                if self.validateValues(forKeys: assetKeysRequiredToPlay, forAsset: newAsset) {
                    
                    self.setupPlayerObservers()
                    self.playerView.playerLayer.player = self.player
                    self.player.replaceCurrentItem(with: AVPlayerItem(asset: newAsset))
                }
            }
        }
    }
    
    func validateValues(forKeys keys: [String], forAsset newAsset: AVAsset) -> Bool {
        for key in keys {
            var error: NSError?
            if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                let stringFormat = NSLocalizedString("The media failed to load the key \"%@\"",
                                                     comment: "You can't use this AVAsset because one of it's keys failed to load.")
                
                let message = String.localizedStringWithFormat(stringFormat, key)
                handleErrorWithMessage(message, error: error)
                
                return false
            }
        }
        
        if !newAsset.isPlayable || newAsset.hasProtectedContent {

            let message = NSLocalizedString("The media isn't playable or it contains protected content.",
                                            comment: "You can't use this AVAsset because it isn't playable or it contains protected content.")
            handleErrorWithMessage(message)
            return false
        }
        
        return true
    }
    
    // MARK: - Key-Value Observing
    func setupPlayerObservers() {
        playerTimeControlStatusObserver = player.observe(\AVPlayer.timeControlStatus,
                                                         options: [.initial, .new]) { [unowned self] _, _ in
            DispatchQueue.main.async {
                self.setPlayPauseButtonImage()
            }
        }
        
        let interval = CMTime(value: 1, timescale: 2)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval,
                                                           queue: .main) { [unowned self] time in
            let timeElapsed = Float(time.seconds)
            self.surfaceDisplay.timeSlider.value = timeElapsed
            self.surfaceDisplay.startTimeLabel.text = self.createTimeString(time: timeElapsed)
            print(self.createTimeString(time: timeElapsed))
        }
        
//        playerItemFastForwardObserver = player.observe(\AVPlayer.currentItem?.canPlayFastForward,
//                                                       options: [.new, .initial]) { [unowned self] player, _ in
//            DispatchQueue.main.async {
//                self.fastForwardButton.isEnabled = player.currentItem?.canPlayFastForward ?? false
//            }
//        }
//
//        playerItemReverseObserver = player.observe(\AVPlayer.currentItem?.canPlayReverse,
//                                                   options: [.new, .initial]) { [unowned self] player, _ in
//            DispatchQueue.main.async {
//                self.rewindButton.isEnabled = player.currentItem?.canPlayReverse ?? false
//            }
//        }
//
//        playerItemFastReverseObserver = player.observe(\AVPlayer.currentItem?.canPlayFastReverse,
//                                                       options: [.new, .initial]) { [unowned self] player, _ in
//            DispatchQueue.main.async {
//                self.rewindButton.isEnabled = player.currentItem?.canPlayFastReverse ?? false
//            }
//        }
        playerItemStatusObserver = player.observe(\AVPlayer.currentItem?.status, options: [.new, .initial]) { [unowned self] _, _ in
            DispatchQueue.main.async {
                
                self.updateUIforPlayerItemStatus()
            }
        }
    }
    
    // MARK: - Error Handling
    func handleErrorWithMessage(_ message: String, error: Error? = nil) {
        if let err = error {
            print("Error occurred with message: \(message), error: \(err).")
        }
        let alertTitle = NSLocalizedString("Error", comment: "Alert title for errors")
        
        let alert = UIAlertController(title: alertTitle, message: message,
                                      preferredStyle: UIAlertController.Style.alert)
        let alertActionTitle = NSLocalizedString("OK", comment: "OK on error alert")
        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)
        alert.addAction(alertAction)
//        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Utilities
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    /// Adjust the play/pause button image to reflect the current play state.
    func setPlayPauseButtonImage() {
        var buttonImage: UIImage?
        
        switch self.player.timeControlStatus {
        case .playing:
            buttonImage = UIImage(named: VJPlayVideoView.pauseButtonImageName)
        case .paused, .waitingToPlayAtSpecifiedRate:
            buttonImage = UIImage(named: VJPlayVideoView.playButtonImageName)
        @unknown default:
            buttonImage = UIImage(named: VJPlayVideoView.pauseButtonImageName)
        }
        guard let image = buttonImage else { return }
        self.surfaceDisplay.playBtn.setImage(image, for: .normal)
    }
    
    func updateUIforPlayerItemStatus() {
        guard let currentItem = player.currentItem else { return }
        
        switch currentItem.status {
        case .failed:
            surfaceDisplay.isEnabled(false)

            handleErrorWithMessage(currentItem.error?.localizedDescription ?? "", error: currentItem.error)
            
        case .readyToPlay:
            surfaceDisplay.isEnabled(true)
            
            let newDurationSeconds = Float(currentItem.duration.seconds)
            let currentTime = Float(CMTimeGetSeconds(player.currentTime()))
            surfaceDisplay.timeSlider.maximumValue = newDurationSeconds
            surfaceDisplay.timeSlider.value = currentTime
            surfaceDisplay.startTimeLabel.text = createTimeString(time: currentTime)
            surfaceDisplay.durationLabel.text = createTimeString(time: newDurationSeconds)
            
        default:
            surfaceDisplay.isEnabled(false)
        }
    }
}


/*
 let keyWindow = UIApplication.shared.connectedScenes
     .map{$0 as? UIWindowScene}
     .compactMap{$0}
     .first?.windows.first
 */

