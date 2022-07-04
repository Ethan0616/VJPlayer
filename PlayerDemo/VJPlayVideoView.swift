//
//  VJPlayVideoView.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/4.
//

import UIKit
import AVFoundation

class VJPlayVideoView: UIView {

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
    
    
    // MARK: layout
    private static let bottomHeight : CGFloat = 150     // 距离底边距离
    private static let playLeftSpace: CGFloat = 20      // 播放按钮左侧空间
    private static let playWidth    : CGFloat = 44      // 播放按钮宽度
    private static let playRightSpace : CGFloat = 10    // 播放按钮右边空间
    private static let labelWidth   : CGFloat = 60      // 时间显示的宽度
    private static let toolViewHeight : CGFloat = 50    // toolBar 高度
    
    // MARK: UI
    fileprivate var  imageView : UIImageView!
    fileprivate var  playView  : AVPlayerLayer!
    fileprivate var  player    : AVPlayer!
    fileprivate var playerItem : AVPlayerItem!
    fileprivate var url        : URL!
    
    fileprivate var timeSlider : UISlider! = {
        let slider  = UISlider()
        slider.addTarget(self, action: #selector(timeSliderDidChange(_:)), for: .valueChanged)
        slider.value = 0
        return slider
    }()
    fileprivate var startTimeLabel : UILabel! = {
      let label = UILabel()
        label.backgroundColor = UIColor.gray
        label.textAlignment = .right
        return label
    }()
    fileprivate var durationLabel : UILabel! = {
        let label = UILabel()
        label.backgroundColor = UIColor.gray
          return label
    }()
    
    fileprivate var playBtn : UIButton! = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        btn.setImage(UIImage(systemName: "play.fill"), for: .highlighted)
        btn.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        return btn
    }()
    
    fileprivate var buttons : Array<String>!
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        setUpAssets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect,btns: Array<String>) {
        self.init(frame: frame)
        buttons = btns
        setUpAssets()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if imageView != nil{
            imageView.frame = self.bounds
            self.insertSubview(imageView, at: 0)
        }
        if playView != nil{
            playView.frame = self.bounds
            playView.fillMode = .backwards
            self.layer.insertSublayer(playView, at: 0)
            playView.frame = self.bounds
        }
        playBtn.frame = CGRect(x: VJPlayVideoView.playLeftSpace, y: bounds.size.height - VJPlayVideoView.bottomHeight, width: VJPlayVideoView.playWidth, height: 44)
        startTimeLabel.frame = CGRect(x: playBtn.frame.origin.x + playBtn.frame.size.width + VJPlayVideoView.playRightSpace, y: bounds.size.height - VJPlayVideoView.bottomHeight , width: VJPlayVideoView.labelWidth, height: 44)
        let timeSliderWidth : CGFloat =  bounds.size.width - (VJPlayVideoView.playLeftSpace * 2 + VJPlayVideoView.playRightSpace + VJPlayVideoView.playWidth  + VJPlayVideoView.labelWidth * 2 + 10)
        let timeSliderLeft : CGFloat = VJPlayVideoView.playLeftSpace + VJPlayVideoView.playWidth + VJPlayVideoView.playRightSpace + VJPlayVideoView.labelWidth + 5
        timeSlider.frame = CGRect(x: timeSliderLeft, y: bounds.size.height - VJPlayVideoView.bottomHeight , width: timeSliderWidth, height: 44)
        durationLabel.frame = CGRect(x: timeSlider.frame.origin.x + timeSlider.frame.size.width + 5, y: bounds.size.height - VJPlayVideoView.bottomHeight, width: VJPlayVideoView.labelWidth, height: 44)
    }
    
    deinit {
        removePlayer()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setUpAssets() {
        // 设置静音模式下播放
//        let avSession = AVAudioSession.sharedInstance()
//        try! avSession.setCategory(.playback)
        backgroundColor = UIColor.black
        addSubview(timeSlider)
        addSubview(startTimeLabel)
        addSubview(durationLabel)
        addSubview(playBtn)
        clipsToBounds = true
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

                    self.playView.player = self.player
                    
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
            self.timeSlider.value = timeElapsed
            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
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
        self.playBtn.setImage(image, for: .normal)
    }
    
    func updateUIforPlayerItemStatus() {
        guard let currentItem = player.currentItem else { return }
        
        switch currentItem.status {
        case .failed:

            playBtn.isEnabled = false
            timeSlider.isEnabled = false
            startTimeLabel.isEnabled = false
            durationLabel.isEnabled = false
            handleErrorWithMessage(currentItem.error?.localizedDescription ?? "", error: currentItem.error)
            
        case .readyToPlay:
            
            playBtn.isEnabled = true
            
            let newDurationSeconds = Float(currentItem.duration.seconds)
            
            let currentTime = Float(CMTimeGetSeconds(player.currentTime()))
            
            timeSlider.maximumValue = newDurationSeconds
            timeSlider.value = currentTime
            timeSlider.isEnabled = true
            startTimeLabel.isEnabled = true
            startTimeLabel.text = createTimeString(time: currentTime)
            durationLabel.isEnabled = true
            durationLabel.text = createTimeString(time: newDurationSeconds)
            
        default:
            playBtn.isEnabled = false
            timeSlider.isEnabled = false
            startTimeLabel.isEnabled = false
            durationLabel.isEnabled = false
        }
    }
}

extension VJPlayVideoView {
    
    @objc func playVideo(_ url : URL){

        self.url = url
        if playView != nil{
            playView.isHidden = false
        }
        if imageView != nil{
            imageView.isHidden = true
        }
        
        removePlayer()
        
        playerItem  = AVPlayerItem(url: url )
        player = AVPlayer(playerItem: playerItem)
        playView = AVPlayerLayer(player: player)
        playView.videoGravity = .resizeAspect // 填充方式 充满屏幕  拉伸
        playView.frame = self.bounds
        self.layer.addSublayer(playView)
//        nextPlayer()
//        player.play()
//        addAVPlayItemKVO(playerItem)
        
        let asset = AVURLAsset(url: url)
        
        loadPropertyValues(forAsset: asset)
    }
    
    func removePlayer(){
        if playView != nil{
            playView.removeAllAnimations()
            playView.removeFromSuperlayer()
            playView = nil
            
            if player != nil{
                player = nil
            }
        }
        if imageView != nil{
            imageView.removeFromSuperview()
            imageView = nil
        }
    }
}

extension VJPlayVideoView {
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



