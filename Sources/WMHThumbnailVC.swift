//
//  WMHThumbnailVC.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/12.
//

import UIKit
import Photos

public final class WMHThumbnailVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    static let itemWidth = (WMHScreenWidth - 2.0 * 5.0) / 4.0

    private var titleBack : UIView!
    private var titleLabel : UILabel!
    private var titleArrow : UIImageView!
    private var titleButton : UIButton!
    private var completeButton : WMHCompleteButton!
    private var currentCollection : PHAssetCollection!
    private var originImageView : UIImageView!
    private var preViewButton : UIButton!
    private var originButton : UIButton!
    private var thumbnailDataSource : Array<WMHThumbnailModel> = []
    private var currentSelect : Int = -1
    
    @objc public var requestType = WMHAssetsType.photoAndVideo
    @objc public var selectedDataSource : Array<WMHThumbnailModel> = []
    private var selectedIndexPath : Array<IndexPath> {
        selectedDataSource.map(\.indexPath)
    }
    @objc public var completeBlock:((_ modelArr: Array<WMHThumbnailModel>, _ isSelectOriginal: Bool) -> Void)?
    @objc public var originTag : Bool = false
    @objc public var maxCount : Int = 9
    @objc public var maxVideoDuration : Int = Int.max
    
    lazy var maskerView : UIButton = {
        let masker = UIButton(frame: CGRect(x: 0, y: WMHNavigationBarHeight, width: WMHScreenWidth, height: WMHScreenHeight - WMHNavigationBarHeight))
        masker.backgroundColor = UIColor(white: 0, alpha: 0.75)
        masker.clipsToBounds = true
        masker.alpha = 0
        masker.addTarget(self, action: #selector(masker_action), for: .touchUpInside)
        self.view.addSubview(masker)
        return masker
    }()
    
    lazy var albumListView : WMHAlbumListView = {
        let albumView = WMHAlbumListView(frame: CGRect(x: 0, y: WMHNavigationBarHeight, width: WMHScreenWidth, height: 0))
        albumView.alpha = 0
        albumView.requestType = self.requestType
        albumView.clickItemBlock = {
            [weak self] in
            self?.closeAlbumList()
            self?.thumbnailDataSource.removeAll()
            for asset in WMHPhotoTool.shared.getAssetsInAssetCollection(assetCollection: $0.assetCollection, ascending: true, requestType: self?.requestType != nil ? (self?.requestType)! : .photoAndVideo) {
                self?.currentCollection = $0.assetCollection
                let tnModel = WMHThumbnailModel(asset: asset)
                
                var haveRecord = false
                for model : WMHThumbnailModel  in (self?.selectedDataSource)! {
                    if model.asset == tnModel.asset {
                        haveRecord = true
                        self?.thumbnailDataSource.append(model)
                        break
                    }
                }
                if haveRecord == false {
                    if self?.selectedDataSource.count == self?.maxCount {
                        tnModel.canSelect = false
                    }
                    self?.thumbnailDataSource.append(tnModel)
                }
            }
            
            self?.baseCollect.reloadData()
            self?.baseCollect.scrollToItem(at: IndexPath(item: (self?.thumbnailDataSource.count)! - 1, section: 0), at: .bottom, animated: false)
            self?.titleLabel.text = $0.assetCollection.localizedTitle
        }
        self.maskerView.addSubview(albumView)
        return albumView
    }()
    
    lazy var baseCollect : UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 2
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.itemSize = CGSize(width: WMHThumbnailVC.itemWidth, height: WMHThumbnailVC.itemWidth)
        
        let collect = UICollectionView(frame: CGRect(x: 0, y: WMHNavigationBarHeight, width: WMHScreenWidth, height: WMHScreenHeight - WMHNavigationBarHeight - 55 - WMHSafeAreaBottomHeight), collectionViewLayout: flowLayout)
        collect.bounces = true
        collect.delegate = self
        collect.dataSource = self
        collect.alwaysBounceVertical = true
        collect.contentInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        collect.backgroundColor = UIColor(argb: 0x222222)
        collect.register(WMHBOTools.bundledXib(name: "WMHThumbnailCell"), forCellWithReuseIdentifier: "WMHThumbnailCell")
        return collect
    }()
    
    // MARK: LifeCycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(argb: 0x222222)
        configureView()
        configureNavi()
        WMHPhotoTool.shared.requestAlbumAuthority {[weak self] (success) in
            DispatchQueue.main.async {
                if success == true {
                    self?.loadFirstModelData()
                }else{
                    self?.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: UIConfigure
    func configureNavi() {
        let naviBar = UIView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHNavigationBarHeight))
        naviBar.backgroundColor = UIColor(argb: 0xCC222222)
        self.view.addSubview(naviBar)
        
        let backBtn = UIButton(frame: CGRect(x: 0, y: WMHStatusBarHeight, width: 44, height: 44))
        backBtn.setTitle("取消", for: .normal)
        backBtn.setTitleColor(.white, for: .normal)
        backBtn.titleLabel?.font = WMHFont(fontSize: 14)
        backBtn.addTarget(self, action: #selector(back_action), for: .touchUpInside)
        naviBar.addSubview(backBtn)
        
        titleBack = UIView()
        titleBack.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        titleBack.clipsToBounds = true
        titleBack.layer.cornerRadius = 14.0
        naviBar.addSubview(titleBack)
        titleBack.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.centerX.equalTo(naviBar)
            make.centerY.equalTo(naviBar).offset(WMHStatusBarHeight / 2)
        }
        
        titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = WMHFont(fontSize: 16)
        titleLabel.textAlignment = .center
        titleBack.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleBack.snp_left).offset(15)
            make.right.equalTo(titleBack.snp_right).offset((-33))
            make.centerY.equalTo(titleBack)
        }
        
        titleArrow = UIImageView()
        titleArrow.image = WMHBOTools.bundledImage(name: "WMHArrow_down")
        titleBack.addSubview(titleArrow)
        titleArrow.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp_right).offset(10)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(18)
            make.height.equalTo(18)
        }

        titleButton = UIButton()
        titleButton.backgroundColor = .clear
        titleButton.addTarget(self, action: #selector(albumSelect_action(sender:)), for: .touchUpInside)
        titleBack.addSubview(titleButton)
        titleButton.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        self.view.bringSubviewToFront(naviBar)
    }
    
    func configureView() {
        self.view.addSubview(self.baseCollect)
        
        completeButton = WMHCompleteButton(frame: CGRect(x: WMHScreenWidth - 80, y: WMHScreenHeight - WMHSafeAreaBottomHeight - 41.5, width: 70, height: 28))
        if selectedDataSource.count > 0 {
            completeButton.hightLightAction()
            completeButton.titleLbl.text = String(format: "完成(%d)", selectedDataSource.count)
        }else{
            completeButton.normalAction()
            completeButton.titleLbl.text = "完成"
        }
        completeButton.completeBlock = {
            [weak self] in
            if self?.selectedDataSource.count == 0 {
                return
            }else{
                self?.complete_action()
            }
        }
        self.view.addSubview(completeButton)
        
        originButton = UIButton()
        originButton.backgroundColor = .clear
        originButton.isSelected = originTag
        originButton.addTarget(self, action: #selector(originSelect_action), for: .touchUpInside)
        view.addSubview(originButton)
        originButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(completeButton)
            make.centerX.equalTo(view)
            make.width.equalTo(54)
            make.height.equalTo(20)
        }
        
        originImageView = UIImageView()
        originImageView.image = originTag == true ? WMHBOTools.bundledImage(name: "selectCheck_selected") : WMHBOTools.bundledImage(name: "selectCheck_unSelected")
        originButton.addSubview(originImageView)
        originImageView.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.centerY.equalTo(originButton)
            make.width.height.equalTo(18)
        }
        
        let originLbl = UILabel()
        originLbl.text = "原图"
        originLbl.textColor = .white
        originLbl.textAlignment = .center
        originLbl.font = WMHFont(fontSize: 16)
        originButton.addSubview(originLbl)
        originLbl.snp.makeConstraints { (make) in
            make.left.equalTo(originImageView.snp_right).offset(4)
            make.centerY.equalTo(originButton)
        }
        
        preViewButton = UIButton()
        preViewButton.isSelected = false
        preViewButton.setTitle("预览", for: .normal)
        preViewButton.setTitleColor(.white, for: .selected)
        preViewButton.titleLabel?.font = WMHFont(fontSize: 14)
        if selectedDataSource.count > 0 {
            preViewButton.setTitleColor(.white, for: .normal)
        } else {
            preViewButton.setTitleColor(UIColor(white: 1.0, alpha: 0.4), for: .normal)
        }
        preViewButton.addTarget(self, action: #selector(preView_action), for: .touchUpInside)
        view.addSubview(preViewButton)
        preViewButton.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.centerY.equalTo(originButton)
        }
    }
    
    // MARK: UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ivVC = WMHIVBrowserVC()
        ivVC.thumbnailDataSource = thumbnailDataSource
        ivVC.preViewMode = false
        ivVC.currentIndex = indexPath.item
        ivVC.selectedDataSource = selectedDataSource
        ivVC.maxCount = maxCount
        ivVC.maxVideoDuration = maxVideoDuration
        ivVC.originTag = originTag
        ivVC.completeBlock = self.completeBlock
        ivVC.backBlock = { [weak self] in
            self?.onBrowserBack(selected: $0, thumbnailArray: $1, isOrigin: $2)
        }
        self.navigationController?.pushViewController(ivVC, animated: true)
    }
    
    // MARK: UICollectionViewDataSource
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnailDataSource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : WMHThumbnailCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WMHThumbnailCell", for: indexPath) as! WMHThumbnailCell
        let model = thumbnailDataSource[indexPath.item]
        model.indexPath = indexPath
        cell.configureCellData(model: model, isCurrent: indexPath.row == currentSelect)
        cell.selectPhoto = { [weak self] in
            self?.currentSelect = indexPath.row
            self?.changeSelectStatus(model: $0, selected: $1, at: indexPath)
        }
        return cell
    }
    
    func changeSelectStatus(model: WMHThumbnailModel, selected: Bool, at indexPath: IndexPath) {
        if selected == true {
            //选中
            if Int(model.asset.duration) > maxVideoDuration {
                WMHPhotoTool.shared.showAlert(title: "温馨提示", message: String(format: "最多选择%d秒的视频", maxVideoDuration), controller: self, ensureTitle: "好的", cancelTitle: "") {
                    
                } _: {
                    
                };
                return
            }
            if self.selectedDataSource.count + 1 > self.maxCount {
                //加上选中的对象已经超出最大选择数
                WMHPhotoTool.shared.showAlert(title: kAlertTipTitle, message: String(format: "最多可以选择%d张", self.maxCount), controller: self, ensureTitle: "好的", cancelTitle: "") {
                    
                } _: {
                    
                }
            } else {
                model.selected = true
                selectedDataSource.append(model)
                model.index = selectedDataSource.count
                if self.selectedDataSource.count == self.maxCount {
                    for allModel in self.thumbnailDataSource {
                        allModel.canSelect = false
                        if allModel.selected == true {
                            allModel.canSelect = true
                        }
                    }
                }
                changeActionStatus()
                if self.selectedDataSource.count == self.maxCount {
                    baseCollect.reloadData()
                } else {
                    baseCollect.reloadItems(at: selectedIndexPath)
                }
            }
        } else {
            //取消选择
            model.selected = false
            
            //变化角标
            for index in stride(from: model.index - 1, to: selectedDataSource.count, by: 1) {
                selectedDataSource[index].index -= 1
            }
            
            let oldCount = selectedDataSource.count
            let old = selectedIndexPath
            selectedDataSource.remove(at: model.index)
            
            if self.selectedDataSource.count < maxCount {
                for allModel in self.thumbnailDataSource {
                    allModel.canSelect = true
                }
            }
            changeActionStatus()
            if oldCount == self.maxCount {
                baseCollect.reloadData()
            } else {
                baseCollect.reloadItems(at: old)
            }
        }
    }
    
    // MARK: Action
    @objc func back_action() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func masker_action() {
        closeAlbumList()
    }
    
    @objc func albumSelect_action(sender : UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected == true {
            openAlbumList()
        }else{
            closeAlbumList()
        }
    }
    
    @objc func originSelect_action() {
        originTag = !originTag
        if originTag == true {
            originImageView.image = WMHBOTools.bundledImage(name: "selectCheck_selected")
        }else{
            originImageView.image = WMHBOTools.bundledImage(name: "selectCheck_unSelected")
        }
    }
    
    @objc func preView_action() {
        if selectedDataSource.count > 0 {
            let ivVC = WMHIVBrowserVC()
            ivVC.thumbnailDataSource = selectedDataSource
            ivVC.selectedDataSource = selectedDataSource
            ivVC.preViewDataSource = selectedDataSource
            ivVC.completeBlock = completeBlock
            ivVC.maxCount = maxCount
            ivVC.originTag = originTag
            ivVC.maxVideoDuration = maxVideoDuration
            ivVC.preViewMode = true
            ivVC.preViewBackBlock = {
                self.selectedDataSource.removeAll()
                self.selectedDataSource.append(contentsOf: $0)
                for idx in 0..<self.thumbnailDataSource.count {
                    if $0.count == self.maxCount {
                        self.thumbnailDataSource[idx].canSelect = false
                    }else{
                        self.thumbnailDataSource[idx].canSelect = true
                    }
                    for selectModel in $0 {
                        if selectModel.asset == self.thumbnailDataSource[idx].asset {
                            self.thumbnailDataSource[idx] = selectModel
                            break
                        }
                    }
                }
                self.originTag = $1
                self.originButton.isSelected = $1
                if self.originTag == true {
                    self.originImageView.image = WMHBOTools.bundledImage(name: "selectCheck_selected")
                }else{
                    self.originImageView.image = WMHBOTools.bundledImage(name: "selectCheck_unSelected")
                }
                self.changeActionStatus()
                self.baseCollect.reloadData()
            }
            self.navigationController?.pushViewController(ivVC, animated: true)
        }
    }
    
    func changeActionStatus() {
        if selectedDataSource.count > 0 {
            completeButton.hightLightAction()
            preViewButton.isSelected = true
            completeButton.titleLbl.text = String(format: "完成(%d)", selectedDataSource.count)
        }else{
            completeButton.normalAction()
            preViewButton.isSelected = false
            completeButton.titleLbl.text = "完成"
        }
    }
    
    func openAlbumList() {
        albumListView.refreshData()
        albumListView.currentAssetCollection = currentCollection
        self.albumListView.frame = CGRect(x: 0, y: -WMHScreenHeight, width: WMHScreenWidth, height: 0)
        UIView.animate(withDuration: 0.2) {
            self.titleArrow.transform = CGAffineTransform(rotationAngle: 180.0 * (CGFloat)(Double.pi / 180.0))
            self.maskerView.alpha = 1.0
            self.albumListView.frame = CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight * 2 / 3)
            self.albumListView.alpha = 1.0
        }
    }
    
    func closeAlbumList() {
        self.titleButton.isSelected = false
        self.albumListView.frame = CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight * 2 / 3)
        UIView.animate(withDuration: 0.2) {
            self.titleArrow.transform = .identity
            self.maskerView.alpha = 0.0
            self.albumListView.frame = CGRect(x: 0, y: -WMHScreenHeight, width: WMHScreenWidth, height: WMHScreenHeight * 2 / 3)
            self.albumListView.alpha = 0.0
        }
    }
    
    func getFirstAlbum() -> WMHAlbumListModel? {
        print(self.requestType)
        return WMHPhotoTool.shared.getFirstAlbum(requestType: self.requestType, ascending: true)
    }
    
    func loadFirstModelData() {
        currentCollection = WMHPhotoTool.shared.getFirstCollection()
        self.albumListView.currentAssetCollection = currentCollection
        titleLabel.text = currentCollection.localizedTitle
        self.thumbnailDataSource.removeAll()
        var assetArr : Array<PHAsset> = []
        
        if currentCollection != nil {
            for asset in WMHPhotoTool.shared.getAssetsInAssetCollection(assetCollection: currentCollection, ascending: true, requestType: self.requestType) {
                let tnModel = WMHThumbnailModel(asset: asset)
                var haveRecord = false
                var haveModel : WMHThumbnailModel?
                for selectModel in selectedDataSource {
                    if selectModel.asset == asset {
                        haveRecord = true
                        haveModel = selectModel
                        break
                    }
                }
                if haveRecord == true {
                    self.thumbnailDataSource.append(haveModel!)
                    assetArr.append(haveModel!.asset)
                }else{
                    self.thumbnailDataSource.append(tnModel)
                    assetArr.append(asset)
                }
            }
        }
        baseCollect.reloadData()
        baseCollect.scrollToItem(at: IndexPath(item: thumbnailDataSource.count - 1, section: 0), at: .bottom, animated: false)
    }
    
    @objc func complete_action() {
        if completeBlock != nil {
            completeBlock!(selectedDataSource, originTag)
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func onBrowserBack(selected: [WMHThumbnailModel], thumbnailArray: [WMHThumbnailModel], isOrigin: Bool) {
        self.selectedDataSource.removeAll()
        self.selectedDataSource.append(contentsOf: selected)
        self.thumbnailDataSource.removeAll()
        self.thumbnailDataSource.append(contentsOf: thumbnailArray)
        self.originTag = isOrigin
        self.originButton.isSelected = isOrigin
        if self.originTag {
            self.originImageView.image = WMHBOTools.bundledImage(name: "selectCheck_selected")
        }else{
            self.originImageView.image = WMHBOTools.bundledImage(name: "selectCheck_unSelected")
        }
        self.baseCollect.reloadData()
        self.changeActionStatus()
    }
}
