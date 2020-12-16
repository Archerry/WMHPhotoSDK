//
//  WMHThumbnailCell.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/12.
//

import UIKit
import Photos
import EGOCache

class WMHThumbnailCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImg: UIImageView!
    @IBOutlet weak var selectImg: UIImageView!
    @IBOutlet weak var maskerView: UIView!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var videoImg: UIImageView!
    @IBOutlet weak var videoDurationLbl: UILabel!
    @IBOutlet weak var indexLbl: UILabel!

    private var requestID: PHImageRequestID?

    var currentModel: WMHThumbnailModel?
    public var selectPhoto: ((_ selectModel: WMHThumbnailModel, _ selecte: Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        maskerView.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
        videoDurationLbl.font = WMHFont(fontSize: 12)
        videoDurationLbl.textColor = .white
        videoImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Video")
        indexLbl.textColor = .white
    }

    override func prepareForReuse() {
        if let id = requestID {
            WMHPhotoTool.shared.cancelImageRequest(id)
        }
        requestID = nil
//        thumbnailImg.image = nil
    }

    public func configureCellData(model: WMHThumbnailModel, isCurrent: Bool) {
        currentModel = model

        let itemWidth = (WMHScreenWidth - 2.0 * 5.0) / 4.0

        let cacheImage = EGOCache.global().image(forKey: model.asset.localIdentifier)
        if cacheImage != nil {
            thumbnailImg.image = cacheImage
        } else {
            requestID = WMHPhotoTool.shared.requestImage(asset: model.asset, size: CGSize(width: itemWidth, height: itemWidth), resizeMode: .fast, deliveryMode: .highQualityFormat) { [weak self] result in
                if let image = result.value {
                    EGOCache.global().setImage(image, forKey: model.asset.localIdentifier)
                    self?.thumbnailImg.image = image
                }
            }
        }


        if model.asset.mediaType == .video {
            videoImg.isHidden = false
            videoDurationLbl.isHidden = false
            videoDurationLbl.text = WMHPhotoTool.shared.getVideoDurationStr(duration: Int(model.asset.duration))
        } else {
            videoImg.isHidden = true
            videoDurationLbl.isHidden = true
        }

        if model.selected == true {
            indexLbl.text = String(format: "%d", model.index)
            selectBtn.isSelected = true
            selectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Selected")
            self.maskerView.isHidden = false
            self.maskerView.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
            if isCurrent == true {
                showOscillatoryAnimation(layer: selectImg.layer)
            } else {
                //do nothing
            }
        } else {
            indexLbl.text = ""
            selectBtn.isSelected = false
            selectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Unselect")
            if model.canSelect == true {
                self.maskerView.isHidden = true
            } else {
                self.maskerView.isHidden = false
                self.maskerView.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
            }
        }
    }

    @IBAction func selectPhoto_action(_ sender: UIButton) {
        if let selectPhoto = selectPhoto {
            selectPhoto(self.currentModel!, !self.currentModel!.selected)
        }
    }

    func showOscillatoryAnimation(layer: CALayer) {
        let scale1 = 1.15
        let scale2 = 0.92

        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            layer.setValue(scale1, forKeyPath: "transform.scale")
        } completion: { (finished) in
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                layer.setValue(scale2, forKeyPath: "transform.scale")
            } completion: { (finished) in
                UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                    layer.setValue(1.0, forKeyPath: "transform.scale")
                } completion: { (finished) in

                }

            }

        }

    }
}
