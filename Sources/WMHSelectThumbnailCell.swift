//
//  WMHSelectThumbnailCell.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/16.
//

import UIKit
import Photos

class WMHSelectThumbnailCell: UICollectionViewCell {
    @IBOutlet weak var assetImgView: UIImageView!
    @IBOutlet weak var videoImg: UIImageView!
    @IBOutlet weak var borderImg: UIImageView!    
    private var requestID : PHImageRequestID?

    override func awakeFromNib() {
        super.awakeFromNib()
        videoImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Video")
        borderImg.image = WMHBOTools.bundledImage(name: "selectBorder")
    }
    
    override func prepareForReuse() {
        if let id = requestID {
            WMHPhotoTool.shared.cancelImageRequest(id)
        }
        requestID = nil
    }

    public func configureCellData(model: WMHThumbnailModel, currentModel: WMHThumbnailModel?) {
        if model.asset == currentModel?.asset {
            borderImg.isHidden = false
        }else{
            borderImg.isHidden = true
        }
        
        if model.asset.mediaType == .video {
            videoImg.isHidden = false
        }else{
            videoImg.isHidden = true
        }

        let itemWidth = (WMHScreenWidth - 2.0 * 5.0) / 4.0
        
        requestID = WMHPhotoTool.shared.requestImage(asset: model.asset, size: CGSize(width: itemWidth * 2.5, height: itemWidth * 2.5), resizeMode: .exact, deliveryMode: .highQualityFormat) { [weak self] result in
            self?.assetImgView.image = result.value
        }
    }
}
