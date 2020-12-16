//
//  WMHAlbumListView.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/12.
//

import UIKit
import Photos
import SnapKit

class WMHAlbumListView: UIView, UITableViewDelegate, UITableViewDataSource {
    var currentAssetCollection: PHAssetCollection?
    var thumbDataSource: Array<WMHAlbumListModel> = []
    var requestType: WMHAssetsType = .photoAndVideo
    var clickItemBlock: ((_ model: WMHAlbumListModel) -> Void)?

    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = UIColor(argb: 0x222222)
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.rowHeight = WMHAlbumListCell.height
        table.separatorStyle = .none
        table.register(WMHAlbumListCell.self, forCellReuseIdentifier: "WMHAlbumListCell")
        return table
    }()

    //MARK: LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    //MARK: UIConfigure
    func configureViews() {
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    //MARK: Action
    public func refreshData() {
        thumbDataSource.removeAll()
        thumbDataSource += WMHPhotoTool.shared.getAlbumList(requestType: requestType)
        tableView.reloadData()
    }

    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickItemBlock?(thumbDataSource[indexPath.row])
    }

    //MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        thumbDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let raw = tableView.dequeueReusableCell(withIdentifier: "WMHAlbumListCell", for: indexPath)
        guard let cell = raw as? WMHAlbumListCell else {
            return raw
        }
        cell.configureCellData(model: thumbDataSource[indexPath.row],
            isCurrent: currentAssetCollection?.localIdentifier ==
                thumbDataSource[indexPath.row].assetCollection.localIdentifier)
        return cell
    }
}
