//
//  WMHPhotoTool.swift
//  Pods-WMHPhotoSDK_Example
//
//  Created by Archer on 2020/10/10.
//

import Foundation
import Photos
import MediaPlayer
import EGOCache

let kAlertTipTitle = "温馨提示"
let kAuthorizationCancelTitle = "下次吧"
let kAuthorizationEnsureTitle = "去开启"
let kAuthorityAlbumMessage = "未获得读取手机存储权限，开启后可上传和保存图片，现在去开启吧"
let kAuthorityCameraMessage = "未能开启摄像头权限，开启后可直接进行拍摄，现在去开启吧"

/// 相册模型
public class WMHAlbumListModel: NSObject {
    /// 相册标题
    @objc public internal(set) var albumTitle = ""
    /// 相册数量
    @objc public internal(set) var albumCount = 0
    /// 相册首张图片的asset
    @objc public internal(set) var headImageAsset: PHAsset
    /// 相册colleciton对象
    @objc public internal(set) var assetCollection: PHAssetCollection
    /// 相册id
    @objc public internal(set) var albumId = ""
    
    @objc init(headImageAsset: PHAsset, assetCollection: PHAssetCollection, assetsCount: Int) {
        self.headImageAsset = headImageAsset
        self.assetCollection = assetCollection
        self.albumTitle = assetCollection.localizedTitle != nil ? assetCollection.localizedTitle! : ""
        self.albumCount = assetsCount
        self.albumId = assetCollection.localIdentifier
    }
}

/// 图片模型
public class WMHThumbnailModel: NSObject {
    /// 图片asset对象
    @objc public internal(set) var asset: PHAsset
    /// 图片大图缓存图片
    @objc public internal(set) var cacheImg: UIImage?
    /// 图片缩略图缓存图片
    @objc public internal(set) var cacheThumbImg: UIImage?
    /// 视频播放item
    @objc public internal(set) var playerItem: AVPlayerItem?
    /// 选中标识
    @objc public internal(set) var selected: Bool = false
    /// 选中角标
    @objc public internal(set) var index: Int = 0
    /// 可选标识
    @objc public internal(set) var canSelect: Bool = true
    
    var indexPath = IndexPath(row: 0, section: 0)

    @objc init(asset: PHAsset) {
        self.asset = asset
    }
}

/// 图片选择类型
@objc public enum WMHAssetsType: Int {
    /// 图片
    case photo
    /// 视频
    case video
    /// 图片以及视频
    case photoAndVideo
}

/// 图片选择通用管理工具
public class WMHPhotoTool: NSObject {
    @objc public static let shared = WMHPhotoTool()

    private override init() {
    }
    
    @objc public internal(set) var kCollectionName = ""
    @objc public internal(set) var prepareFirstArr: [WMHThumbnailModel] = []
    @objc public internal(set) var prepareFirstImageArr: [WMHThumbnailModel] = []
    @objc public internal(set) var prepareFirstVideoArr: [WMHThumbnailModel] = []
    @objc public internal(set) var prepareImageAndVideoAlbumArr: [WMHAlbumListModel] = []
    @objc public internal(set) var prepareImageAlbumArr: [WMHAlbumListModel] = []
    @objc public internal(set) var prepareVideoAlbumArr: [WMHAlbumListModel] = []
    @objc public internal(set) var haveCached: Bool = false
    @objc public internal(set) var haveCachedAlbum: Bool = false

    /// 获取第一个相册（相机胶卷）
    /// - parameters:
    ///   - requestType: 所选类型
    ///   - ascending: 排序顺序
    /// - returns: WMHAlbumListModel: 相册模型
    @objc public func getFirstAlbum(requestType: WMHAssetsType, ascending: Bool) -> WMHAlbumListModel? {
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        var resultModel: WMHAlbumListModel?

        smartAlbums.enumerateObjects { (obj, idx, stop) in
            if obj.assetCollectionSubtype == PHAssetCollectionSubtype(rawValue: 209) {
                let assets: Array<PHAsset> = self.getAssetsInAssetCollection(assetCollection: obj, ascending: ascending, requestType: requestType)
                resultModel = WMHAlbumListModel(headImageAsset: assets.first!, assetCollection: obj, assetsCount: assets.count)
                stop.pointee = true
            }
        }
        return resultModel
    }

    /// 获取第一个相册Collection（相机胶卷）
    /// - parameter requestType 所选类型
    /// - returns: PHAssetCollection: 相册collection对象
    @objc public func getFirstCollection() -> PHAssetCollection? {
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        var collection: PHAssetCollection?
        smartAlbums.enumerateObjects { (obj, idx, stop) in
            if obj.assetCollectionSubtype == PHAssetCollectionSubtype(rawValue: 209) {
                collection = obj
                stop.pointee = true
            }
        }
        return collection
    }

    // MARK: 相册相关
    /// 获取所有相册列表
    /// - parameters
    ///  requestType 所选类型
    /// - returns: WMHAlbumListModel数组
    @objc public func getAlbumList(requestType: WMHAssetsType) -> Array<WMHAlbumListModel> {
        let option = PHFetchOptions()
        if requestType == .photo {
            option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        } else if requestType == .video {
            option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        } else if requestType == .photoAndVideo {

        }

        var photoAlbumList: Array<WMHAlbumListModel> = []
        //获取所有智能相册
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        smartAlbums.enumerateObjects { (collection, idx, stop) in
            //过滤掉最近删除和慢动作
            if collection.assetCollectionSubtype != PHAssetCollectionSubtype(rawValue: 1000000201) && collection.assetCollectionSubtype != PHAssetCollectionSubtype(rawValue: 208) {
                let assetResult = PHAsset.fetchAssets(in: collection, options: option)
                if assetResult.count > 0 {
                    let albumModel = WMHAlbumListModel(headImageAsset: assetResult.firstObject!, assetCollection: collection, assetsCount: assetResult.count)
                    photoAlbumList.append(albumModel)
                }
            }
        }

        //获取用户创建的相册
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary, options: nil)
        userAlbums.enumerateObjects { (collection, idx, stop) in
            let assetResult = PHAsset.fetchAssets(in: collection, options: option)
            if assetResult.count > 0 {
                let albumModel = WMHAlbumListModel(headImageAsset: assetResult.firstObject!, assetCollection: collection, assetsCount: assetResult.count)
                photoAlbumList.append(albumModel)
            }
        }

        var sortAlbumList: Array<WMHAlbumListModel> = []
        for album in photoAlbumList {
            if album.assetCollection.assetCollectionSubtype == PHAssetCollectionSubtype(rawValue: 209) {
                sortAlbumList.insert(album, at: 0)
            } else if album.albumTitle == "九机网" {
                sortAlbumList.insert(album, at: 1)
            } else if album.albumTitle == "CH999OA" {
                sortAlbumList.insert(album, at: 2)
            } else {
                sortAlbumList.append(album)
            }
        }

        if prepareVideoAlbumArr.count > 0 &&
               prepareImageAndVideoAlbumArr.count > 0 &&
               prepareImageAlbumArr.count > 0 {
            haveCachedAlbum = true
        }
        return sortAlbumList
    }

    /// 获取指定相册内的多张图片
    /// - parameters:
    ///     - count: 拿取张数
    ///     - assetCollection: 相册collection
    ///     - ascending: 排序
    ///     - requestType: 选择获取asset对象类型
    /// - returns: PHAsset对象数组
    @objc public func getSomeAssetsInAssetCollection(count: Int, assetCollection: PHAssetCollection, ascending: Bool, requestType: WMHAssetsType) -> Array<PHAsset> {
        var resultArr = Array<PHAsset>()

        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        if requestType == .photo {
            option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(in: assetCollection, options: option)
            result.enumerateObjects { (obj, idx, stop) in
                resultArr.append(obj)
                if resultArr.count == count {
                    stop.pointee = true
                }
            }
            return resultArr
        } else if requestType == .video {
            option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let result = PHAsset.fetchAssets(in: assetCollection, options: option)
            result.enumerateObjects { (obj, idx, stop) in
                resultArr.append(obj)
                if resultArr.count == count {
                    stop.pointee = true
                }
            }
            return resultArr
        } else {
            //选择图片和视频
            let result = PHAsset.fetchAssets(in: assetCollection, options: option)
            result.enumerateObjects { (obj, idx, stop) in
                resultArr.append(obj)
                if resultArr.count == count {
                    stop.pointee = true
                }
            }
            return resultArr
        }
    }

    /// 获取指定相册内的所有图片
    /// - parameters:
    ///     - assetCollection: 相册collection
    ///     - ascending: 排序
    ///     - requestType: 选择获取asset对象类型
    /// - returns: PHAsset对象数组
    @objc public func getAssetsInAssetCollection(assetCollection: PHAssetCollection, ascending: Bool, requestType: WMHAssetsType) -> Array<PHAsset> {
        var resultArr = Array<PHAsset>()

        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        if requestType == .photo {
            option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(in: assetCollection, options: option)
            result.enumerateObjects { (obj, idx, stop) in
                resultArr.append(obj)
            }
            return resultArr
        } else if requestType == .video {
            option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let result = PHAsset.fetchAssets(in: assetCollection, options: option)
            result.enumerateObjects { (obj, idx, stop) in
                resultArr.append(obj)
            }
            return resultArr
        } else {
            //选择图片和视频
            let result = PHAsset.fetchAssets(in: assetCollection, options: option)
            result.enumerateObjects { (obj, idx, stop) in
                resultArr.append(obj)
            }
            return resultArr
        }
    }

    /// 通过 `PHAsset` 获取对应的图片。公共接口。
    /// - Parameters:
    ///   - asset: 图片asset。
    ///   - size: 图片大小。
    ///   - resizeMode: 图片质量。
    ///   - deliveryMode: 图片数据传输模式。
    ///   - completion: 获取图片完成回调。
    /// - Returns: 从 PHImageManager 得到的 Request ID。
    @available(*, deprecated,
        message: "Please use 'requestImage(asset:size:resizeMode:deliveryMode:completion)' instead.")
    @objc public func getImage(asset: PHAsset, size: CGSize,
        resizeMode: PHImageRequestOptionsResizeMode,
        deliveryMode: PHImageRequestOptionsDeliveryMode,
        completion: @escaping (_ image: UIImage) -> Void) -> PHImageRequestID {
        requestImage(asset: asset, size: size, resizeMode: resizeMode,
            deliveryMode: deliveryMode) { result in
            if let image = result.value {
                completion(image)
            }
        }
    }

    /// 通过 `PHAsset` 获取对应的图片。公共接口。
    /// - Parameters:
    ///   - asset: 图片asset
    ///   - size: 图片大小
    ///   - resizeMode: 图片质量
    ///   - deliveryMode: 图片数据传输模式
    ///   - completion: 获取图片完成回调
    /// - Returns: 从 PHImageManager 得到的 Request ID
    @objc public func requestImage(asset: PHAsset, size: CGSize,
        resizeMode: PHImageRequestOptionsResizeMode,
        deliveryMode: PHImageRequestOptionsDeliveryMode,
        completion: @escaping (ResultBox<UIImage>) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.resizeMode = resizeMode
        options.deliveryMode = deliveryMode
        options.isNetworkAccessAllowed = true
        return PHImageManager.default()
            .requestImage(for: asset, targetSize: size, contentMode: .aspectFill,
                options: options) { (resultImage, info) in
                if let image = resultImage {
                    let box = ResultBox(value: image)
                    DispatchQueue.main.async {
                        completion(box)
                    }
                } else if let error = info?[PHImageErrorKey] as? NSError {
                    let box = ResultBox<UIImage>(error: error)
                    DispatchQueue.main.async {
                        completion(box)
                    }
                }
            }
    }

    /// 通过 `PHAsset` 获取对应的图片data。公共接口。
    /// - Parameters:
    ///   - asset: 图片asset
    ///   - resizeMode: 图片质量
    ///   - deliveryMode: 图片数据传输模式
    ///   - completion: 获取图片data完成回调
    @objc
    public func geImageData(asset: PHAsset, resizeMode: PHImageRequestOptionsResizeMode,
                            deliveryMode: PHImageRequestOptionsDeliveryMode,
                            completion: @escaping (_ imageData: Data?) -> Void) {
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        option.resizeMode = resizeMode
        option.deliveryMode = deliveryMode
        option.isNetworkAccessAllowed = true
        PHImageManager.default().requestImageData(for: asset, options: option) {
            (imageData: Data?, dataUIT: String?, _, _) in
            guard let imageData = imageData else {
                completion(nil)
                return
            }
            guard dataUIT == "public.heif" || dataUIT == "public.heic",
                  let ciImage = CIImage(data: imageData),
                  let colorSpace = ciImage.colorSpace else {
                completion(imageData)
                return
            }
            if #available(iOS 10.0, *) {
                let context = CIContext()
                let jpgData = context.jpegRepresentation(of: ciImage, colorSpace: colorSpace)
                completion(jpgData ?? imageData)
            } else {
                completion(imageData)
            }
        }
    }

    // 取消图片获取请求
    @objc public func cancelImageRequest(_ requestID: PHImageRequestID) {
        PHImageManager.default().cancelImageRequest(requestID)
    }

    func getDestinationAlbum() -> PHAssetCollection? {
        var assetAlbum: PHAssetCollection?
        if self.kCollectionName.count > 0 {
            //看保存的指定相册是否存在
            let list = PHAssetCollection
                .fetchAssetCollections(with: .album, subtype: .any, options: nil)
            list.enumerateObjects({ (album, index, stop) in
                let assetCollection = album
                if self.kCollectionName == assetCollection.localizedTitle {
                    assetAlbum = assetCollection
                    stop.initialize(to: true)
                }
            })
            //不存在的话则创建该相册
            if assetAlbum == nil {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest
                        .creationRequestForAssetCollection(withTitle: self.kCollectionName)
                }, completionHandler: { (isSuccess, error) in

                })
            }
            return assetAlbum
        } else {
            return nil
        }
    }

    /// 保存图片到系统相册
    /// - Parameters:
    ///   - image: 图片
    ///   - completion: 保存图片完成回调
    @objc public func saveImageToAlbum(image: UIImage, _ completion: @escaping (_ success: Bool, _ asset: PHAsset?) -> Void) {
        requestAlbumAuthority { [weak self] (success) in
            if success == true {
                var placeholderAsset: PHObjectPlaceholder = PHObjectPlaceholder()
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    placeholderAsset = request.placeholderForCreatedAsset!
                } completionHandler: { (saveSuccess, error) in
                    if saveSuccess == false {
                        completion(false, nil)
                    }
                    let asset = self?.getAssetFromlocalIdentifier(localId: placeholderAsset.localIdentifier)
                    let desCollection = self?.getDestinationAlbum()
                    if desCollection == nil {
                        completion(true, nil)
                    } else {
                        PHPhotoLibrary.shared().performChanges {
                            let albumChangeRequest = PHAssetCollectionChangeRequest(for: desCollection!)
                            albumChangeRequest!.addAssets([asset!] as NSArray)
                        } completionHandler: { (resultSuccess, error) in
                            completion(resultSuccess, asset)
                        }
                    }
                }
            } else {
                
            }

        }
    }

    func getAssetFromlocalIdentifier(localId: String?) -> PHAsset? {
        if localId == nil {
            return nil
        }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localId!], options: nil)
        if result.count > 0 {
            return result[0]
        }
        return nil
    }

    ///获取相册权限
    public func requestAlbumAuthority(complete: @escaping (_ success: Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            complete(true)
        } else if (status == PHAuthorizationStatus.notDetermined) {
            PHPhotoLibrary.requestAuthorization { (requestStatus) in
                if requestStatus == .authorized {
                    complete(true)
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.showAlert(title: kAlertTipTitle, message: kAuthorityAlbumMessage, controller: self?.getCurrentVC(), ensureTitle: kAuthorizationEnsureTitle, cancelTitle: kAuthorizationCancelTitle) {
                            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                            complete(false)
                        } _: {
                            complete(false)
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: kAlertTipTitle, message: kAuthorityAlbumMessage, controller: self?.getCurrentVC(), ensureTitle: kAuthorizationEnsureTitle, cancelTitle: kAuthorizationCancelTitle) {
                    UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                    complete(false)
                } _: {
                    complete(false)
                }
            }
        }
    }

    /// 获取图片data
    @objc public func getImageData(asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, deliveryMode: PHImageRequestOptionsDeliveryMode, completion: @escaping (_ data: Data?) -> Void) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = deliveryMode

        PHImageManager.default().requestImageData(for: asset, options: option) { (imageData, dataUIT, orientation, info) in
            if let tempData = imageData {
                if dataUIT == "public.heif" || dataUIT == "public.heic" {
                    let ciImage = CIImage(data: tempData)
                    let context = CIContext()
                    if let resultCiImage = ciImage {
                        if #available(iOS 10.0, *) {
                            let jpgData = context.jpegRepresentation(of: resultCiImage, colorSpace: resultCiImage.colorSpace!, options: [:])
                            if let resultData = jpgData {
                                completion(resultData)
                            }else{
                                completion(tempData)
                            }
                        } else {
                            completion(tempData)
                        }
                    }else{
                        completion(tempData)
                    }
                }else{
                    completion(tempData)
                }
            } else {
                completion(nil)
            }
        }
    }


    /// MARK: 视频
    /// - parameters:
    ///     - asset: 媒体源
    ///     - completion: 返回AVPlayerItem对象
    @objc public func getVideo(asset: PHAsset, completion: @escaping (_ playItem: AVPlayerItem) -> Void) {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { (playerItem, info) in
            DispatchQueue.main.async {
                if playerItem != nil {
                    completion(playerItem!)
                }
            }
        }
    }

    /// 获取视频url
    /// - parameters:
    ///     - asset: 媒体源
    ///     - completion: 返回url和data
    @objc public func getVideoUrl(asset: PHAsset, completion: @escaping (_ url: URL, _ data: Data?) -> Void) {
        if asset.mediaType == .video {
            let option = PHVideoRequestOptions()
            option.version = .current
            option.deliveryMode = .automatic

            PHImageManager.default().requestAVAsset(forVideo: asset, options: option) { (asset, audioMix, info) in
                let urlAsset: AVURLAsset = asset as! AVURLAsset
                var data: Data?
                do {
                    data = try Data(contentsOf: urlAsset.url)
                } catch {
                    print("获取失败")
                }

                if data == nil {
                    completion(urlAsset.url, nil)
                } else {
                    completion(urlAsset.url, data!)
                }
            }
        }
    }

    @objc public func getVideoDurationStr(duration: Int) -> String {
        var resultTime = ""
        if duration < 10 {
            resultTime = String(format: "00:0%d", duration)
        } else if duration < 60 {
            resultTime = String(format: "00:%d", duration)
        } else {
            let min = duration / 60
            let sec = duration - (min * 60)
            if sec < 10 {
                resultTime = String(format: "%d:0%d", min, sec)
            } else {
                resultTime = String(format: "%d:%d", min, sec)
            }
        }
        return resultTime
    }

    /// 展示弹窗
    /// - parameters:
    ///     - title: 弹窗标题
    ///     - message: 弹窗内容
    ///     - controller: 控制器
    ///     - ensureTitle: 确定按钮文本
    ///     - cancelTitle: 取消按钮文本
    ///     - ensureAction: 确定按钮回调事件
    ///     - cancelAction: 取消按钮回调事件
    func showAlert(title: String, message: String, controller: UIViewController?, ensureTitle: String, cancelTitle: String, _ ensureAction: @escaping () -> Void, _ cancelAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if ensureTitle.count > 0 {
            let ensureAct = UIAlertAction(title: ensureTitle, style: .default) { (action) in
                ensureAction()
            }
            alert.addAction(ensureAct)
        }

        if cancelTitle.count > 0 {
            let cancelAct = UIAlertAction(title: cancelTitle, style: .default) { (action) in
                cancelAction()
            }
            alert.addAction(cancelAct)
        }
        if controller != nil {
            controller!.present(alert, animated: true, completion: nil)
        } else {
            if let currentVC = getCurrentVC() {
                currentVC.present(alert, animated: true, completion: nil)
            }
        }
    }

    func showAlert(title: String, message: String, on controller: UIViewController?,
        ensure: String? = nil, cancel: String? = nil, onEnsure: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let ensure = ensure {
            let action = UIAlertAction(title: ensure, style: .default) { _ in
                onEnsure?()
            }
            alert.addAction(action)
        }
        if let cancel = cancel {
            let action = UIAlertAction(title: cancel, style: .default) { (action) in
                onCancel?()
            }
            alert.addAction(action)
        }
        if let currentVC = getCurrentVC() {
            currentVC.present(alert, animated: true)
        }
    }
    
    func getCurrentVC() -> (UIViewController?) {
       var window = UIApplication.shared.keyWindow
       if window?.windowLevel != UIWindow.Level.normal{
         let windows = UIApplication.shared.windows
         for  windowTemp in windows{
           if windowTemp.windowLevel == UIWindow.Level.normal{
              window = windowTemp
              break
            }
          }
        }
       let vc = window?.rootViewController
       return currentViewController(vc)
    }


    func currentViewController(_ vc :UIViewController?) -> UIViewController? {
       if vc == nil {
          return nil
       }
       if let presentVC = vc?.presentedViewController {
          return currentViewController(presentVC)
       }
       else if let tabVC = vc as? UITabBarController {
          if let selectVC = tabVC.selectedViewController {
              return currentViewController(selectVC)
           }
           return nil
        }
        else if let naiVC = vc as? UINavigationController {
           return currentViewController(naiVC.visibleViewController)
        }
        else {
           return vc
        }
     }
}
