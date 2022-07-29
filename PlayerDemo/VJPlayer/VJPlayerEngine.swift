//
//  VJPlayerEngine.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/21.
//

import UIKit
import AVFoundation

public typealias SliderDisplaySetUp = (_ enable:Bool,_ currentValue:Float,_ startText:String,_ maxValue:Float,_ durationText:String) -> Void
public typealias SliderDisplay = (_ currentValue : Float ,_ startText: String ) -> Void
public typealias SliderButtonImage = (_ isPlay: Bool) -> Void


internal class VJPlayerEngine: NSObject {

    fileprivate var playValue : Float = -1
    fileprivate var isPlaying : Bool = false
    fileprivate weak var playerLayer : AVPlayerLayer? = nil
    fileprivate var player      : AVPlayer!
    fileprivate var playerItem  : AVPlayerItem!
    fileprivate var url         : URL!
    // MARK: Properties
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    public static var sliderDisplaySetUp : SliderDisplaySetUp! = nil
    public static var sliderDisplay : SliderDisplay! = nil
    public static var sliderPlayButtonImage : SliderButtonImage! = nil
    public var playAction : ((Bool)->Void)? = nil

    private var timeObserverToken: Any?
    private var playerItemStatusObserver: NSKeyValueObservation?
//    private var playerItemFastForwardObserver: NSKeyValueObservation?
//    private var playerItemReverseObserver: NSKeyValueObservation?
//    private var playerItemFastReverseObserver: NSKeyValueObservation?
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    
    let pauseButtonImageName = "PauseButton"
    let playButtonImageName = "PlayButton"
    
    
    private static let engine : VJPlayerEngine = VJPlayerEngine()
    static func shared() -> VJPlayerEngine {
        return VJPlayerEngine.engine
    }
    
    /// 播放
    /// - Parameter url: 播放资源
    static func showVideo(_ url : URL , closure : @escaping (_ playLayer : AVPlayerLayer) -> Void) {
        engine.showVideo(url, closure: closure)
    }
    
    /// 视图点击事件播放切换
    static func togglePlay() {
        engine.togglePlay()
    }
    
    /// 滑块拖拽事件
    /// - Parameter value: 滑块值
    static func sliderValueChanged(_ value:Float) {
        engine.sliderValueChanged(value)
    }
    
    static func addPeriodicTimeObserver() {
        engine.addPeriodicTimeObserver()
    }
    
    static func removePeriodicTimeObserver() {
        engine.removePeriodicTimeObserver()
    }
    
    /// 正在播放中
    /// - Returns: true 正在播放中
    static func currentlyPlaying() -> Bool{
        return engine.currentlyPlaying()
    }
    
    /// 开始播放
    static func startPlay() {
        engine.startPlay()
    }
    
    /// 暂停播放
    static func pause() {
        engine.pause()
    }
    
    /// 停止播放
    static func stopPlay() {
        engine.stopPlay()
    }
    
    /// 退出播放器
    static func exitPlayback() {
        engine.exitPlayback()
    }
    
    
    /// 播放
    /// - Parameter url: 播放资源
    func showVideo(_ url : URL , closure : @escaping (_ playLayer : AVPlayerLayer) -> Void) {
        // 设置静音模式下播放
//        let avSession = AVAudioSession.sharedInstance()
//        try! avSession.setCategory(.playback)
        
        self.url = url
        playerItem  = AVPlayerItem(url: url )
        player = AVPlayer(playerItem: playerItem)
        removePlayer()
        let tempPlayerLayer = AVPlayerLayer(player: player)
//        print(tempPlayerLayer)
        self.playerLayer = tempPlayerLayer
        closure(tempPlayerLayer)
        startPlay()
        let asset = AVURLAsset(url: url)
        loadPropertyValues(forAsset: asset)
    }
    
    /// 视图点击事件播放切换
    func togglePlay() {
        switch player.timeControlStatus {
        case .playing:
            player.pause()
            playAction?(false)
        case .paused:
            let currentItem = player.currentItem
            // 修复了当滑块拖拽到影片结束，需要连续点击两次才能再次播放的bug
            if let durationValue = currentItem?.duration.value, let currentValue = currentItem?.currentTime().value  {
                let difValue = durationValue - currentValue
                if difValue >= 0 && difValue < 10 {
                    currentItem?.seek(to: .zero, completionHandler: { finsh in })
                }
                print(durationValue)
                print(currentValue)
                print(difValue)
            }
            
            player.play()
            playAction?(true)
        default:
            player.pause()
            playAction?(true)
        }
    }
    
    /// 滑块拖拽事件（手动）
    /// - Parameter value: 滑块值
    func sliderValueChanged(_ value: Float) {
//        print("\(value) ===============")
        let newTime = CMTime(seconds: Double(value), preferredTimescale: 1000)
        print("滑块拖拽事件 time:\(value)")
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    
    /// 播放器监听事件 (自动)
    func addPeriodicTimeObserver() {
        if timeObserverToken != nil { return }
        print("将要添加监听====================")
        let interval = CMTime(value: 1, timescale: 2)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval,
                                                           queue: .main) { [unowned self] time in
            let timeElapsed = Float(time.seconds)
            let textStr = self.createTimeString(time: timeElapsed)
            print("time监听事件 time:\(timeElapsed)")
            VJPlayerEngine.sliderDisplay(timeElapsed,textStr)
        }
    }
    
    // remove a registered time observer
    func removePeriodicTimeObserver() {
        // If a time observer exists, remove it
        guard let timeObserverToken = timeObserverToken else { return }
        objc_sync_enter(self)
        print("将要移除observer==============")
        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
        print("移除监听完成====================")
        objc_sync_exit(self)
    }
    
    /// 正在播放中
    /// - Returns: true 正在播放中
    func currentlyPlaying() -> Bool{
        return self.player.timeControlStatus == .playing
    }
    
    /// 开始播放
    func startPlay() {
        player.play()
    }
    
    /// 暂停播放
    func pause() {
        playerLayer?.player?.pause()
    }
    
    /// 停止播放
    func stopPlay() {
        removePlayer()

    }
    
    /// 退出播放器
    func exitPlayback() {
        stopPlay()
        resourceRelease()
    }
    
    /// 释放内存
    private func resourceRelease() {
        removePeriodicTimeObserver()
        player = nil
        playerItem = nil
        url = nil
    }
    
    @objc private func removePlayer(){
        if let playerLayer = playerLayer {
            playerLayer.player?.pause()
            playerLayer.removeAllAnimations()
            playerLayer.removeFromSuperlayer()
        }
        playerLayer = nil
    }
}

extension VJPlayerEngine {
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
                    self.playerLayer?.player = self.player
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
                if self.player != nil {
                    self.setPlayPauseButtonImage()
                }
            }
        }
        
        // 增加播放监听
        addPeriodicTimeObserver()
        
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

        switch self.player.timeControlStatus {
        case .playing:
            playAction?(true)
            VJPlayerEngine.sliderPlayButtonImage(true)
        case .paused:
            playAction?(false)
            VJPlayerEngine.sliderPlayButtonImage(false)
        case  .waitingToPlayAtSpecifiedRate:
//            playAction?(false)
            print(" .waitingToPlayAtSpecifiedRate")
        @unknown default:
            playAction?(false)
            VJPlayerEngine.sliderPlayButtonImage(false)
        }
    }
    
    
    func updateUIforPlayerItemStatus() {
        guard let currentItem = player.currentItem else { return }

        switch currentItem.status {
        case .failed:
            VJPlayerEngine.sliderDisplaySetUp(false,0,"",0,"")
            handleErrorWithMessage(currentItem.error?.localizedDescription ?? "", error: currentItem.error)
            break
        case .readyToPlay:
            let newDurationSeconds = Float(currentItem.duration.seconds)
            let currentTime = Float(CMTimeGetSeconds(player.currentTime()))
            //   (_ enable:Bool,_ startValue:Float,_ startText:String,_ maxValue:Float,_ durationText:String)
            VJPlayerEngine.sliderDisplaySetUp(true,currentTime,createTimeString(time: currentTime),newDurationSeconds,createTimeString(time: newDurationSeconds))
            break
        default:
            VJPlayerEngine.sliderDisplaySetUp(false,0,"",0,"")
            break
        }
    }
}
