//
//  WMHAlbumListCell.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/12.
//

import UIKit

final class WMHAlbumListCell: UITableViewCell {
    static let height: CGFloat = 50

    private let albumImageView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let checkImageView = UIImageView()
    private let lineView = UIView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }
    
    private func configureViews() {
        contentView.addSubview(self.albumImageView)
        albumImageView.snp.makeConstraints { (make) in
            make.left.top.equalTo(0)
            make.width.height.equalTo(50)
        }
        
        contentView.addSubview(self.titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(albumImageView.snp_right).offset(14)
            make.centerY.equalTo(contentView)
        }

        contentView.addSubview(self.countLabel)
        countLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp_right).offset(5)
            make.centerY.equalTo(contentView)
        }

        contentView.addSubview(self.lineView)
        lineView.snp.makeConstraints { (make) in
            make.bottom.equalTo(contentView)
            make.left.equalTo(50)
            make.right.equalTo(contentView)
            make.height.equalTo(0.5)
        }
        
        contentView.addSubview(self.checkImageView)
        checkImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(22)
            make.right.equalTo(contentView.snp_right).offset(-20)
            make.centerY.equalTo(contentView)
        }

        selectionStyle = .none
        titleLabel.textColor = UIColor.white
        countLabel.textColor = UIColor.white
        countLabel.alpha = 0.4
        checkImageView.image = WMHBOTools.bundledImage(name: "WMHAlbumListSelect")
        contentView.backgroundColor = UIColor(argb: 0x222222)
        lineView.backgroundColor = UIColor(white: 1, alpha: 0.2)
    }

    func configureCellData(model: WMHAlbumListModel, isCurrent: Bool) {
        _ = WMHPhotoTool.shared.requestImage(asset: model.headImageAsset, size: CGSize(width: 50, height: 50), resizeMode: .fast, deliveryMode: .opportunistic) { result in
            self.albumImageView.image = result.value
        }
        titleLabel.text = model.albumTitle
        checkImageView.isHidden = !isCurrent
        countLabel.text = "(\(model.albumCount))"
    }
}
