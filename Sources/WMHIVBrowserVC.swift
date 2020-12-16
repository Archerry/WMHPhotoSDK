//
//  WMHIVBrowserVC.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/13.
//

import UIKit

class WMHIVBrowserVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate {
    public var thumbnailDataSource : Array<WMHThumbnailModel> = []
    public var selectedDataSource : Array<WMHThumbnailModel> = []
    public var preViewDataSource : Array<WMHThumbnailModel> = []
    public var currentIndex = 0
    public var originTag : Bool = false
    var preViewMode : Bool = false
    var showActionSwitch : Bool!
    var playTag : Bool!
    var topView : UIView!
    var topSelectImg : UIImageView!
    var topSelectLbl : UILabel!
    var topSelectBtn : UIButton!
    var bottomView : UIView!
    var noSelectBottomView : UIView!
    var originImg : UIImageView!
    var originBtn : UIButton!
    var completeBtn : WMHCompleteButton!
    var maxCount : Int!
    var maxVideoDuration : Int!
    var backBlock: ((_ selectedArr: Array<WMHThumbnailModel>, _ thumbnailArr: Array<WMHThumbnailModel>, _ isOrigin: Bool) -> Void)?
    var preViewBackBlock: ((_ selectedArr: Array<WMHThumbnailModel>, _ isOrigin: Bool) -> Void)?
    @objc public internal(set) var completeBlock:((_ modelArr: Array<WMHThumbnailModel>, _ isSelectOriginal: Bool) -> Void)?
    
    lazy var baseCollect : UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: WMHScreenWidth, height: WMHScreenHeight)
        
        let collect = UICollectionView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHScreenHeight), collectionViewLayout: flowLayout)
        collect.delegate = self
        collect.dataSource = self
        collect.isPagingEnabled = true
        collect.showsVerticalScrollIndicator = false
        collect.showsHorizontalScrollIndicator = false
        collect.register(WMHIVBrowserCell.self, forCellWithReuseIdentifier: "WMHIVBrowserCell")
        return collect
    }()
    
    lazy var selectCollect : UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 58, height: 58)
        
        let collect = UICollectionView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: 78), collectionViewLayout: flowLayout)
        collect.delegate = self
        collect.dataSource = self
        collect.backgroundColor = .clear
        collect.alwaysBounceVertical = false
        collect.alwaysBounceHorizontal = true
        collect.showsVerticalScrollIndicator = false
        collect.showsHorizontalScrollIndicator = false
        collect.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 0)
        collect.register(WMHBOTools.bundledXib(name: "WMHSelectThumbnailCell"), forCellWithReuseIdentifier: "WMHSelectThumbnailCell")
        return collect
    }()
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initVariables()
        configureUI()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.baseCollect.contentOffset = CGPoint(x: self.currentIndex * Int(WMHScreenWidth), y: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: UIConfigure
    func configureUI() {
        self.view.backgroundColor = .black
        self.view.addSubview(self.baseCollect)
        
        if #available(iOS 11.0, *) {
            self.baseCollect.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        topView = UIView(frame: CGRect(x: 0, y: 0, width: WMHScreenWidth, height: WMHNavigationBarHeight))
        topView.backgroundColor = UIColor(argb: 0xCC222222)
        self.view.addSubview(topView)
        
        let backBtn = UIButton(frame: CGRect(x: 0, y: WMHStatusBarHeight, width: 44, height: 44))
        backBtn.setImage(WMHBOTools.bundledImage(name: "WMHBack_white"), for: .normal)
        backBtn.addTarget(self, action: #selector(back_action), for: .touchUpInside)
        topView.addSubview(backBtn)
        
        topSelectImg = UIImageView(image: WMHBOTools.bundledImage(name: thumbnailDataSource[self.currentIndex].selected == true ? "WMHPhoto_Selected" : "WMHPhoto_Unselect"))
        topSelectImg.frame = CGRect(x: WMHScreenWidth - 38, y: backBtn.frame.origin.y + (backBtn.frame.size.height - 24) / 2, width: 24, height: 24)
        topView.addSubview(topSelectImg)
        
        topSelectLbl = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        if thumbnailDataSource[self.currentIndex].selected == true {
            topSelectLbl.text = String(format: "%d", thumbnailDataSource[self.currentIndex].index)
            topSelectLbl.isHidden = false
        }else{
            topSelectLbl.isHidden = true
        }
        topSelectLbl.textColor = .white
        topSelectLbl.textAlignment = .center
        topSelectLbl.font = WMHBoldFont(fontSize: 12)
        topSelectImg.addSubview(topSelectLbl)
        
        topSelectBtn = UIButton(frame: CGRect(x: WMHScreenWidth - 44, y: WMHStatusBarHeight, width: 44, height: 44))
        topSelectBtn.backgroundColor = .clear
        topSelectBtn.isSelected = thumbnailDataSource[self.currentIndex].selected
        topSelectBtn.addTarget(self, action: #selector(select_action(sender:)), for: .touchUpInside)
        topView.addSubview(topSelectBtn)
        
        noSelectBottomView = UIView(frame: CGRect(x: 0, y: WMHScreenHeight - WMHSafeAreaBottomHeight - 55, width: WMHScreenWidth, height: 55 + WMHSafeAreaBottomHeight))
        noSelectBottomView.backgroundColor = UIColor(argb: 0x66222222)
        self.view.addSubview(noSelectBottomView)
        let noSelectBottomBlurEffect = UIBlurEffect(style: .dark)
        let noSelectBottomVisualView = UIVisualEffectView(effect: noSelectBottomBlurEffect)
        noSelectBottomVisualView.alpha = 1.5
        noSelectBottomVisualView.frame = noSelectBottomView.bounds
        noSelectBottomView.addSubview(noSelectBottomVisualView)
                
        bottomView = UIView(frame: CGRect(x: 0, y: WMHScreenHeight - WMHSafeAreaBottomHeight - 55 - 78, width: WMHScreenWidth, height: 55 + WMHSafeAreaBottomHeight + 78))
        bottomView.backgroundColor = UIColor(argb: 0x66222222)
        self.view.addSubview(bottomView)
        
        let bottomBlurEffect = UIBlurEffect(style: .dark)
        let bottomVisualView = UIVisualEffectView(effect: bottomBlurEffect)
        bottomVisualView.alpha = 1.5
        bottomVisualView.frame = bottomView.bounds
        bottomView.addSubview(bottomVisualView)
        
        if selectedDataSource.count > 0 {
            bottomView.isHidden = false
            noSelectBottomView.isHidden = true
        }else{
            bottomView.isHidden = true
            noSelectBottomView.isHidden = false
        }
        
        completeBtn = WMHCompleteButton(frame: CGRect(x: WMHScreenWidth - 80, y: WMHScreenHeight - WMHSafeAreaBottomHeight - 13.5 - 28, width: 70, height: 28))
        if selectedDataSource.count > 0 {
            completeBtn.hightLightAction()
            completeBtn.titleLbl.text = String(format: "完成(%d)", selectedDataSource.count)
        }else{
            completeBtn.normalAction()
            completeBtn.titleLbl.text = "完成"
        }
        completeBtn.completeBlock = {
            [weak self] in
            if self?.preViewMode == true {
                if self?.preViewDataSource.count == 0 {
                    return
                }else{
                    self?.complete_action()
                }
            }else{
                if self?.selectedDataSource.count == 0 {
                    return
                }else{
                    self?.complete_action()
                }
            }
        }
        self.view.addSubview(completeBtn)
        
        originBtn = UIButton()
        originBtn.backgroundColor = .clear
        originBtn.isSelected = originTag
        originBtn.addTarget(self, action: #selector(originSelect_action), for: .touchUpInside)
        view.addSubview(originBtn)
        originBtn.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.centerY.equalTo(completeBtn)
            make.width.equalTo(54)
            make.height.equalTo(20)
        }
        
        originImg = UIImageView()
        originImg.image = originTag == true ? WMHBOTools.bundledImage(name: "selectCheck_selected") : WMHBOTools.bundledImage(name: "selectCheck_unSelected")
        originBtn.addSubview(originImg)
        originImg.snp.makeConstraints { (make) in
            make.centerY.equalTo(originBtn)
            make.left.equalTo(0)
            make.width.height.equalTo(18)
        }
        
        let originLbl = UILabel()
        originLbl.text = "原图"
        originLbl.textColor = .white
        originLbl.textAlignment = .center
        originLbl.font = WMHFont(fontSize: 16)
        originBtn.addSubview(originLbl)
        originLbl.snp.makeConstraints { (make) in
            make.left.equalTo(originImg.snp_right).offset(4)
            make.centerY.equalTo(originBtn)
        }
        
        bottomView.addSubview(selectCollect)
        selectCollect.isHidden = selectedDataSource.count > 0 ? false : true
        selectCollect.reloadData()
    }
    
    // MARK: Actions
    func initVariables() {
        showActionSwitch = true
        playTag = false
    }
    
    @objc func back_action() {
        if preViewMode == true {
            if preViewBackBlock != nil {
                preViewBackBlock!(preViewDataSource, originTag)
            }
        }else{
            if backBlock != nil {
                backBlock!(selectedDataSource, thumbnailDataSource, originTag)
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func tapCollec_action() {
        showActionSwitch = !showActionSwitch
        showActionSwitch == true ? showActionView() : hideActionView()
    }
    
    func changePlayStatus() {
        playTag = !playTag
    }
    
    func hideActionView() {
        topView.isHidden = true
        completeBtn.isHidden = true
        originBtn.isHidden = true
        if selectedDataSource.count == 0 {
            noSelectBottomView.isHidden = true
        }else{
            bottomView.isHidden = true
        }
    }
    
    func showActionView() {
        topView.isHidden = false
        completeBtn.isHidden = false
        originBtn.isHidden = false
        if selectedDataSource.count == 0 {
            noSelectBottomView.isHidden = false
        }else{
            bottomView.isHidden = false
        }
    }
    
    @objc func select_action(sender: UIButton) {
        if preViewMode == true {
            preViewModeUpdate(sender: sender)
        }else{
            normalViewUpdate(sender: sender)
        }
    }
    
    func preViewModeUpdate(sender: UIButton) {
        var currentIVModel : WMHThumbnailModel?
        currentIVModel = thumbnailDataSource[Int(self.baseCollect.contentOffset.x / WMHScreenWidth)]
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            completeBtn.hightLightAction()
            noSelectBottomView.isHidden = true
            selectCollect.isHidden = false
            bottomView.isHidden = false
            currentIVModel?.selected = true
            currentIVModel?.index = preViewDataSource.count + 1
            preViewDataSource.append(currentIVModel!)
            if self.preViewDataSource.count == self.maxCount {
                for allModel in self.thumbnailDataSource {
                    allModel.canSelect = false
                    if allModel.selected == true {
                        allModel.canSelect = true
                    }
                }
            }
            self.topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Selected")
            showOscillatoryAnimation(layer: topSelectImg.layer)
            topSelectLbl.isHidden = false
            topSelectLbl.text = String(format: "%d", currentIVModel!.index)
            self.completeBtn.titleLbl.text = String(format: "完成(%d)", preViewDataSource.count)
            selectCollect.reloadData()
            baseCollect.reloadData()
        }else{
            currentIVModel?.selected = false
            //变化角标
            for index in stride(from: currentIVModel!.index - 1, to: preViewDataSource.count, by: 1) {
                preViewDataSource[index].index -= 1
            }
            preViewDataSource.remove(at: currentIVModel!.index)
            
            if self.preViewDataSource.count < self.maxCount {
                for allModel in self.thumbnailDataSource {
                    allModel.canSelect = true
                }
            }
            if self.preViewDataSource.count == 0 {
                completeBtn.normalAction()
            }
            self.topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Unselect")
            topSelectLbl.isHidden = true
            self.completeBtn.titleLbl.text = preViewDataSource.count == 0 ? "完成" : String(format: "完成(%d)", preViewDataSource.count)
            selectCollect.reloadData()
            baseCollect.reloadData()
        }
    }
    
    func normalViewUpdate(sender: UIButton) {
        var currentIVModel : WMHThumbnailModel?
        currentIVModel = thumbnailDataSource[Int(self.baseCollect.contentOffset.x / WMHScreenWidth)]
        
        if sender.isSelected == false {
            if Int(currentIVModel!.asset.duration) > maxVideoDuration {
                WMHPhotoTool.shared.showAlert(title: "温馨提示", message: String(format: "最多选择%d秒的视频", maxVideoDuration), controller: self, ensureTitle: "好的", cancelTitle: "") {
                    
                } _: {
                    
                };
                return
            }
            //还未选中，即将进行选中
            if selectedDataSource.count + 1 > maxCount {
                //加上选中的对象已经超出最大选择数
                WMHPhotoTool.shared.showAlert(title: kAlertTipTitle, message: String(format: "最多可以选择%d张", self.maxCount), controller: self, ensureTitle: "好的", cancelTitle: "") {
                    
                } _: {
                    
                }
            }else{
                //可以进行选择
                completeBtn.hightLightAction()
                sender.isSelected = !sender.isSelected
                noSelectBottomView.isHidden = true
                selectCollect.isHidden = false
                bottomView.isHidden = false
                currentIVModel?.selected = true
                currentIVModel?.index = selectedDataSource.count + 1
                selectedDataSource.append(currentIVModel!)
                if self.selectedDataSource.count == self.maxCount {
                    for allModel in self.thumbnailDataSource {
                        allModel.canSelect = false
                        if allModel.selected == true {
                            allModel.canSelect = true
                        }
                    }
                }
                self.topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Selected")
                showOscillatoryAnimation(layer: topSelectImg.layer)
                topSelectLbl.isHidden = false
                topSelectLbl.text = String(format: "%d", currentIVModel!.index)
                self.completeBtn.titleLbl.text = String(format: "完成(%d)", selectedDataSource.count)
                selectCollect.reloadData()
                baseCollect.reloadData()
            }
        }else{
            //已经选中，即将取消选中
            sender.isSelected = !sender.isSelected
            currentIVModel?.selected = false
            //变化角标
            for index in stride(from: currentIVModel!.index - 1, to: selectedDataSource.count, by: 1) {
                selectedDataSource[index].index -= 1
            }
            selectedDataSource.remove(at: currentIVModel!.index)
            if selectedDataSource.count == 0 {
                noSelectBottomView.isHidden = false
                bottomView.isHidden = true
                completeBtn.normalAction()
            }else{
                noSelectBottomView.isHidden = true
                bottomView.isHidden = false
            }
            if self.selectedDataSource.count < self.maxCount {
                for allModel in self.thumbnailDataSource {
                    allModel.canSelect = true
                }
            }
            self.topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Unselect")
            topSelectLbl.isHidden = true
            self.completeBtn.titleLbl.text = selectedDataSource.count == 0 ? "完成" : String(format: "完成(%d)", selectedDataSource.count)
            selectCollect.reloadData()
            baseCollect.reloadData()
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
    
    @objc func originSelect_action() {
        originTag = !originTag
        if originTag == true {
            originImg.image = WMHBOTools.bundledImage(name: "selectCheck_selected")
        }else{
            originImg.image = WMHBOTools.bundledImage(name: "selectCheck_unSelected")
        }
    }
    
    @objc func complete_action() {
        if completeBlock != nil {
            if self.preViewMode == true {
                completeBlock!(preViewDataSource, self.originTag)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }else{
                completeBlock!(selectedDataSource, self.originTag)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: UIScrollViewDelegate    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        playTag = false
        for cell in self.baseCollect.visibleCells {
            let currentCell = cell as! WMHIVBrowserCell
            if currentCell.currentModel != nil {
                let model = currentCell.currentModel!
                if model.asset.mediaType == .video {
                    currentCell.pause()
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == baseCollect {
            selectCollect.reloadData()
            
            var currentIVModel : WMHThumbnailModel?
            let index = Int(self.baseCollect.contentOffset.x / WMHScreenWidth)
            currentIVModel = thumbnailDataSource[index]
            changeActionStatus(currentIVModel: currentIVModel, index: index)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == baseCollect {
            selectCollect.reloadData()
            
            var currentIVModel : WMHThumbnailModel?
            var index = 0
            if scrollView.contentOffset.x.truncatingRemainder(dividingBy: WMHScreenWidth) > WMHScreenWidth / 2 {
                index = Int(ceil(self.baseCollect.contentOffset.x / WMHScreenWidth))
                if index < thumbnailDataSource.count {
                    currentIVModel = thumbnailDataSource[Int(index)]
                    changeActionStatus(currentIVModel: currentIVModel, index: index)
                }
            }else{
                index = Int(floor(self.baseCollect.contentOffset.x / WMHScreenWidth))
                if index > 0 {
                    currentIVModel = thumbnailDataSource[Int(index)]
                    changeActionStatus(currentIVModel: currentIVModel, index: index)
                }
            }
        }
    }
    
    func changeActionStatus(currentIVModel: WMHThumbnailModel?, index: Int) {
        for i in 0..<selectedDataSource.count {
            if currentIVModel?.asset == selectedDataSource[i].asset {
                let index = IndexPath(item: i, section: 0)
                selectCollect.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                break
            }
        }
        
        if currentIVModel!.asset.mediaType == .video {
            originBtn.isHidden = true
        }else{
            if showActionSwitch == true {
                originBtn.isHidden = false
            }else{
                originBtn.isHidden = true
            }
        }
        
        if currentIVModel?.selected == true {
            topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Selected")
            topSelectLbl.isHidden = false
            topSelectLbl.text = String(format: "%d", currentIVModel!.index)
            topSelectBtn.isSelected = true
        }else {
            topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Unselect")
            topSelectLbl.isHidden = true
            topSelectBtn.isSelected = false
        }
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == selectCollect {
            for i in 0..<thumbnailDataSource.count {
                if selectedDataSource[indexPath.item].asset == thumbnailDataSource[i].asset {
                    baseCollect.setContentOffset(CGPoint(x: Int(WMHScreenWidth) * i, y: 0), animated: false)
                    var currentIVModel : WMHThumbnailModel?
                    currentIVModel = thumbnailDataSource[Int(self.baseCollect.contentOffset.x / WMHScreenWidth)]
                    for i in 0..<selectedDataSource.count {
                        if currentIVModel?.asset == selectedDataSource[i].asset {
                            let index = IndexPath(item: i, section: 0)
                            selectCollect.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                            if currentIVModel?.selected == true {
                                topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Selected")
                                topSelectLbl.isHidden = false
                                topSelectLbl.text = String(format: "%d", currentIVModel!.index)
                            }else {
                                topSelectImg.image = WMHBOTools.bundledImage(name: "WMHPhoto_Unselect")
                                topSelectLbl.isHidden = true
                            }
                            selectCollect.reloadData()
                            break
                        }
                    }
                    break
                }
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == selectCollect {
            return 1
        }else{
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == selectCollect {
            return selectedDataSource.count
        }else{
            return thumbnailDataSource.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == selectCollect {
            let cell : WMHSelectThumbnailCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WMHSelectThumbnailCell", for: indexPath) as! WMHSelectThumbnailCell
            
            var currentIVModel : WMHThumbnailModel?
            currentIVModel = thumbnailDataSource[Int(self.baseCollect.contentOffset.x / WMHScreenWidth)]
            cell.configureCellData(model: selectedDataSource[indexPath.item], currentModel: currentIVModel)
            return cell
        }else{
            let cell : WMHIVBrowserCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WMHIVBrowserCell", for: indexPath) as! WMHIVBrowserCell
            let model = thumbnailDataSource[indexPath.item]
            model.indexPath = indexPath
            cell.configureCellData(model: model)
            cell.singleTapBlock = {
                if $0.asset.mediaType == .video {
                    if self.playTag == true {
                        cell.pause()
                        if self.showActionSwitch == false {
                            self.tapCollec_action()
                        }
                    }else{
                        cell.play()
                        if self.showActionSwitch == true {
                            self.tapCollec_action()
                        }
                    }
                    self.changePlayStatus()
                }else{
                    self.tapCollec_action()
                }
            }
            cell.playComplete = {
                self.playTag = false
                self.showActionSwitch = true
                self.showActionView()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == baseCollect {
            let browserCell = cell as! WMHIVBrowserCell
            browserCell.resetScale()
        }
    }
}
