//
//  WMHIVBrowserCell.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/13.
//

import UIKit
import MediaPlayer
import Foundation

class WMHIVBrowserCell: UICollectionViewCell, UIScrollViewDelegate {
    var backView : UIView!
    public var currentModel : WMHThumbnailModel?
    public var scaleScroll : UIScrollView!
    var assetImg : UIImageView!
    var playImg : UIImageView!
    var singleTapBlock:((_ model: WMHThumbnailModel) -> Void)?
    var playComplete:(() -> Void)?
    var player : AVPlayer!
    var playerLayer : AVPlayerLayer!
    var playView : UIView!
    // 加载进度，适用于iCloud图片
    private let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
    
    var singleTap : UITapGestureRecognizer!
    var doubleTap : UITapGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
    }
    
    func configureCell() {                
        scaleScroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight))
        scaleScroll.delegate = self
        scaleScroll.scrollsToTop = false
        scaleScroll.maximumZoomScale = 3
        scaleScroll.minimumZoomScale = 1
        scaleScroll.delaysContentTouches = false
        scaleScroll.isMultipleTouchEnabled = true
        scaleScroll.backgroundColor = .black
        scaleScroll.showsVerticalScrollIndicator = false
        scaleScroll.showsHorizontalScrollIndicator = false
        self.contentView.addSubview(scaleScroll)

        singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap_action(tap:)))
        scaleScroll.addGestureRecognizer(singleTap)
        
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap_action(tap:)))
        doubleTap.numberOfTapsRequired = 2
        scaleScroll.addGestureRecognizer(doubleTap)
        
        singleTap.require(toFail: doubleTap)
        
        backView = UIView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight))
        backView.backgroundColor = .black
        scaleScroll.addSubview(backView)
        
        assetImg = UIImageView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight))
        assetImg.clipsToBounds = true
        assetImg.backgroundColor = .black
        assetImg.contentMode = .scaleAspectFit
        backView.addSubview(assetImg)
        
        playImg = UIImageView(frame: CGRect(x: (WMHScreenWidth - 72) / 2, y: (WMHScreenHeight - 72) / 2, width: 72, height: 72))
        playImg.image = WMHBOTools.bundledImage(name: "WMHVideoPlay")
        playImg.isHidden = true
        self.contentView.addSubview(playImg)
        
        playView = UIView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight))
        playView.backgroundColor = .black
        playView.isHidden = true
        scaleScroll.addSubview(playView)
        
        contentView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints { (make) in
            make.center.equalTo(contentView)
        }
        indicatorView.isHidden = true
    }
    
    public func configureCellData(model: WMHThumbnailModel) {
        currentModel = model
        let scale = UIScreen.main.scale
        let width : CGFloat = min(WMHScreenWidth, WMHScreenHeight)
        let pixelHeight : CGFloat = CGFloat(model.asset.pixelHeight)
        let pixetWidth : CGFloat = CGFloat(model.asset.pixelWidth)
        let height : CGFloat = width * scale * pixelHeight / pixetWidth
        let size = CGSize(width: width * scale, height: height)
        
        if model.asset.mediaType == .video {
            doubleTap.isEnabled = false
            playImg.isHidden = false
            
            scaleScroll.minimumZoomScale = 1.0
            scaleScroll.maximumZoomScale = 1.0
            
            WMHPhotoTool.shared.getVideo(asset: model.asset) { (playItem) in
                self.currentModel?.playerItem = playItem
                self.player = AVPlayer(playerItem: playItem)
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer.videoGravity = .resizeAspectFill
                self.playerLayer.frame = self.playView.frame
                self.playView.layer.addSublayer(self.playerLayer)
                self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main) { (time) in
                    //当前播放时间
                    let currentTime = CMTimeGetSeconds(time)
                    if self.player.currentItem != nil {
                        let totalTime = CMTimeGetSeconds(self.player.currentItem!.duration)
                        if currentTime == totalTime {
                            if self.playComplete != nil {
                                self.playComplete!()
                            }
                            self.playImg.isHidden = false
                            self.player.seek(to: CMTime.zero)
                        }
                    }
                }
            }
        }else{
            scaleScroll.minimumZoomScale = 1.0
            scaleScroll.maximumZoomScale = 3.0
            doubleTap.isEnabled = true
            scaleScroll.isUserInteractionEnabled = true
            playImg.isHidden = true
        }
                
        if model.cacheImg != nil {
            self.assetImg.image = model.cacheImg
            self.resetSubViewSize()
            indicatorView.isHidden = true
        }else{
            indicatorView.isHidden = false
            indicatorView.startAnimating()
            _ = WMHPhotoTool.shared.requestImage(asset: model.asset, size: size, resizeMode: .exact, deliveryMode: .highQualityFormat) { [weak self] result in
                self?.loadImage(result: result)
            }
        }
    }
    
    private func loadImage(result: ResultBox<UIImage>) {
        if let image = result.value {
            currentModel?.cacheImg = image
            assetImg.image = image
            resetSubViewSize()
            indicatorView.stopAnimating()
            indicatorView.isHidden = true
        } else if let error = result.error {
            WMHPhotoTool.shared.showAlert(title: "图片获取失败", message: error.localizedDescription,
                on: nil, ensure: "确定")
        }
    }
    
    public func play() {
        if self.player != nil {
            self.playImg.isHidden = true
            self.playView.isHidden = false
            self.player.play()
        }        
    }
    
    public func pause() {
        if self.player != nil {
            self.playImg.isHidden = false
            self.player.pause()
        }
    }
    
    // MARK: Actions
    func resetSubViewSize() {
        var frame : CGRect = CGRect.zero
        frame.origin = CGPoint.zero
        
        let image = assetImg.image
        if image != nil {
            let imageScale = image!.size.height / image!.size.width
            let screenScale = WMHScreenHeight / WMHScreenWidth
            
            if image!.size.width <= self.frame.size.width &&
                image!.size.height <= self.frame.size.height {
                frame.size.width = image!.size.width
                frame.size.height = image!.size.height
            }else{
                if imageScale > screenScale {
                    frame.size.height = self.frame.size.height
                    frame.size.width = self.frame.size.height / imageScale
                }else{
                    frame.size.width = self.frame.size.width
                    frame.size.height = self.frame.size.width * imageScale
                }
            }
            
            scaleScroll.zoomScale = 1
            scaleScroll.contentSize = frame.size
            scaleScroll.scrollRectToVisible(CGRect.init(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight), animated: false)
            backView.frame = frame
            backView.center = scaleScroll.center
            assetImg.frame = backView.bounds
        }
    }
    
    public func resetScale() {
        self.playView.isHidden = true
        scaleScroll.zoomScale = 1
        if currentModel!.asset.mediaType == .video {
            playImg.isHidden = false
        }else{
            playImg.isHidden = true
        }
        if self.player != nil {
            self.player.seek(to: CMTime.zero)
        }
    }
    
    @objc func doubleTap_action(tap: UITapGestureRecognizer) {
        let scroll : UIScrollView = tap.view as! UIScrollView
        var scale : CGFloat = 1
        if scroll.zoomScale != 3 {
            scale = 3
        }else{
            scale = 1
        }
        let zoomRect = zoomRectForScale(scale: scale, center: tap.location(in: tap.view))
        scroll.zoom(to: zoomRect, animated: true)
    }
    
    @objc func singleTap_action(tap: UITapGestureRecognizer) {
        if singleTapBlock != nil {
            singleTapBlock!(currentModel!)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var resultRect = CGRect.zero
        resultRect.size.height = scaleScroll.frame.size.height / scale
        resultRect.size.width = scaleScroll.frame.size.width / scale
        resultRect.origin.x = center.x - (resultRect.size.width / 2)
        resultRect.origin.y = center.y - (resultRect.size.height / 2)
        return resultRect
    }
    
    // MARK: UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0]
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offX : CGFloat = scrollView.frame.size.width > scrollView.contentSize.width ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offY : CGFloat = scrollView.frame.size.height > scrollView.contentSize.height ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        backView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offX, y: scrollView.contentSize.height * 0.5 + offY)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
