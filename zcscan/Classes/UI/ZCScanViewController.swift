//
//  ZCScanViewController.swift
//  zcscan
//
//  Created by lzc on 2025/7/3.
//

import Foundation
import Foundation
import AVFoundation
import Photos
import AudioToolbox
import UIKit

public enum SearchViewType: Equatable {
    /// 普通
    case normal
    /// 识别二维码
    case recognizeQRCode(img: UIImage?)
}

struct QrcodeResultModel {
    var codeStr: String?
    var codeFrame: CGRect?
}

/// 扫光宽度
private let scanLineW =  UIScreen.main.bounds.width
/// 扫光高度
private let scanLineH =  scanLineW * 0.3791666667
/// 扫光上边距偏移量
private let scanLineTopOffset = 0.1923076923 * UIScreen.main.bounds.height
/// 扫光下边距偏移量
private let scanLineBottomOffset = 0.1923076923 * UIScreen.main.bounds.height
/// 扫光开始位置
private let scanLineStartY = scanLineTopOffset - scanLineH
/// 扫光结束位置
private let scanLineEndY = UIScreen.main.bounds.height - scanLineBottomOffset - scanLineH

public class ZCScanViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    private var metadataOutput: AVCaptureMetadataOutput?
    private var session: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let videoPreview = UIView()
    /// 进入类型
    public var searchType: SearchViewType?
    private var qrCodeResultView: QrcodeSelectView?
    private let scanningline = UIImageView()
    private let manager = ZCScanManager.shared
    private lazy var selectIV: UIImageView = {
        return UIImageView()
    }()

    /** 扫光动画时间*/
    private var animationDuration: CFTimeInterval = 2.5
    private var isPhotoMode = false
    private var isScanning = false
    private var albumClickBlock: ((@escaping (UIImage) -> Void) -> Void)?
    public let linghtView = UIView()
  
    public var resultBlock: ((_ link:String) -> Void)?
    public let navBar = ZCNavView()
    public let albumbtn = UIButton()
    
    @discardableResult
    public static func push(fromVC: UIViewController, type: SearchViewType = .normal,
                       albumClickBlock: ((@escaping (UIImage) -> Void) -> Void)? = nil,
                       resultBlock: ((_ link:String) -> Void)? = nil) -> ZCScanViewController {
        let vc = ZCScanViewController(type: type, albumClickBlock: albumClickBlock, resultBlock: resultBlock)
        fromVC.navigationController?.pushViewController(vc, animated: true)
        return vc
    }
    
    public static func present(fromVC: UIViewController, type: SearchViewType = .normal,
                       albumClickBlock: ((@escaping (UIImage) -> Void) -> Void)? = nil,
                       resultBlock: ((_ link:String) -> Void)? = nil) -> ZCScanViewController {
        let vc = ZCScanViewController(type: type, albumClickBlock: albumClickBlock, resultBlock: resultBlock)
        vc.modalPresentationStyle = .custom
        fromVC.present(vc, animated: true)
        return vc
    }
    
    public init(type: SearchViewType = .normal,
                albumClickBlock: ((@escaping (UIImage) -> Void) -> Void)? = nil,
                resultBlock: ((_ link:String) -> Void)? = nil) {
        self.resultBlock = resultBlock
        self.albumClickBlock = albumClickBlock
        self.searchType = type
        super.init(nibName: nil, bundle: nil)
        self.initUI()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if (self.navigationController?.viewControllers.count ?? 0) > 1 {
            self.hidesBottomBarWhenPushed = true
            self.tabBarController?.tabBar.isHidden = true
        } else {
            self.hidesBottomBarWhenPushed = false
            self.tabBarController?.tabBar.isHidden = false
        }
        self.view.bringSubviewToFront(self.navBar)
        self.requestAuthorization { [weak self] in
            guard let `self` = self else { return }
            self.scanSession()
        }
        self.startScan()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopScan()
    }
    
    func initUI() {
        self.view.backgroundColor = .black
        self.videoPreview.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.view.addSubview(self.videoPreview)
        switch self.searchType {
        case .normal:
            self.createNav()
        case .recognizeQRCode(let image):
            self.recognizeQRCode(img: image)
            return
        default:
            break
        }
        self.scanningline.image = self.manager.conifg.scanninglineImage == nil  ? UIImage(named: "scanner_line", in: Bundle.zcscanBundle, compatibleWith: nil) : self.manager.conifg.scanninglineImage
        self.scanningline.frame = CGRect.init(x: 0, y: scanLineStartY, width: scanLineW, height: scanLineH)
        self.view.insertSubview(self.scanningline, aboveSubview: self.navBar)
        self.scanningline.isHidden = true

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let `self` = self else { return }
            if self.isPhotoMode { return }
            self.startScan()
        }
        NotificationCenter.default.addObserver(forName:  UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.stopScan()
        }
        
        let image = UIImage(named: "light_icon", in: Bundle.zcscanBundle, compatibleWith: nil)
        let linghtBtn = UIButton(frame: .zero)
        linghtBtn.setImage(image, for: .normal)
        linghtBtn.setTitle("轻触点亮", for: .normal)
        linghtBtn.setTitle("轻触关闭", for: .selected)
        linghtBtn.titleLabel?.font = .systemFont(ofSize: 14)
        linghtBtn.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
        self.view.addSubview(self.linghtView)
        self.linghtView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.linghtView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
            self.linghtView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
        self.linghtView.addSubview(linghtBtn)
        linghtBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            linghtBtn.topAnchor.constraint(equalTo: self.linghtView.topAnchor),
            linghtBtn.bottomAnchor.constraint(equalTo: self.linghtView.bottomAnchor),
            linghtBtn.leadingAnchor.constraint(equalTo: self.linghtView.leadingAnchor),
            linghtBtn.trailingAnchor.constraint(equalTo: self.linghtView.trailingAnchor)
        ])
        linghtBtn.zc.tap {[weak self] isSelect in
            guard let `self` = self, let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
            try? device.lockForConfiguration()
            device.torchMode = isSelect ? .on : .off
            device.unlockForConfiguration()
            linghtBtn.isSelected = isSelect
        }
    }
    
    /// 创建导航内容
    private func createNav() {
        self.view.addSubview(self.navBar)
        self.navBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.navBar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.navBar.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.navBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        self.navBar.titleLabel.text = "扫一扫"
        self.navBar.backItem.zc.tap {[weak self] _ in
            guard let `self` = self else { return }
            self.backAction()
        }
    
        self.navBar.bar.addSubview(albumbtn)
        albumbtn.setTitle("相册", for: .normal)
        albumbtn.setTitleColor(.white, for: .normal)
        albumbtn.titleLabel?.font = .systemFont(ofSize: 16)
        albumbtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumbtn.centerYAnchor.constraint(equalTo: self.navBar.bar.centerYAnchor),
            albumbtn.trailingAnchor.constraint(equalTo: self.navBar.bar.trailingAnchor, constant: -16),
            albumbtn.heightAnchor.constraint(equalToConstant: 22)
        ])
        albumbtn.zc.tap {[weak self] _ in
            guard let `self` = self else { return }
            self.photosAction()
        }
    }
    
    public func backAction() {
        if let navigationController = self.navigationController {
            // 如果有导航控制器，尝试 pop
            let viewController = navigationController.popViewController(animated: true)
            if viewController == nil {
                // 如果无法 pop，则 dismiss
                navigationController.dismiss(animated: true, completion: nil)
            }
        } else {
            // 如果没有导航控制器，直接 dismiss
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    deinit {
        self.stopScan()
    }
}

extension ZCScanViewController {
    private func startLineAnimation() {
        self.stopLineAnimation()
        self.scanningline.isHidden = false
        let group = CAAnimationGroup()
        let scanAnimation = CABasicAnimation(keyPath: "position.y")
        scanAnimation.fromValue = scanLineStartY + scanLineH * 0.5
        scanAnimation.toValue = scanLineEndY + scanLineH * 0.5
        scanAnimation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)

        let opacityBeginAnimation = CABasicAnimation(keyPath: "opacity")
        opacityBeginAnimation.fromValue = 0.0
        opacityBeginAnimation.toValue = 1.0
        opacityBeginAnimation.duration = 0.5
        opacityBeginAnimation.beginTime = 0.0

        let opacityEndAnimation = CABasicAnimation(keyPath: "opacity")
        opacityEndAnimation.fromValue = 1.0
        opacityEndAnimation.toValue = 0.0
        opacityEndAnimation.duration = 0.5
        opacityEndAnimation.beginTime = 2

        group.animations = [scanAnimation,opacityBeginAnimation ,opacityEndAnimation]
        group.isRemovedOnCompletion = false
        group.duration = self.animationDuration
        group.fillMode = .forwards
        group.repeatCount = Float(Int64.max)

        self.scanningline.layer.add(group, forKey: "basic")
    }

    private func stopLineAnimation() {
        self.scanningline.layer.removeAllAnimations()
    }
    
    func startScan() {
        if case .recognizeQRCode = self.searchType {
            return
        }
        guard let session = self.session else { return }
        if !session.isRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.isScanning = true
            }
            DispatchQueue.global().async {
                session.startRunning()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.startLineAnimation()
                }
            }
        }
    }

    func stopScan() {
        if case .recognizeQRCode = self.searchType {
            return
        }
        self.isScanning = false
        self.session?.stopRunning()
        self.stopLineAnimation()
    }
    /// 初始化扫码摄像头
    func scanSession() {
        if case .recognizeQRCode = self.searchType {
            return
        }
        guard self.session == nil else { return }
        // 1、获取摄像设备
        // 2、创建摄像设备输入流
        guard let device = AVCaptureDevice.default(for: .video), let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        // 3、创建元数据输出流
        self.metadataOutput = AVCaptureMetadataOutput()
        self.metadataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.global())
        // 设置扫描范围（每一个取值0～1，以屏幕右上角为坐标原点）
        // 4、创建会话对象
        self.session = AVCaptureSession()
        // 并设置会话采集率
        self.session!.sessionPreset = .hd1920x1080

        // 5、添加元数据输出流到会话对象
        self.session?.addOutput(self.metadataOutput!)

        // 创建摄像数据输出流并将其添加到会话对象上,  --> 用于识别光线强弱
//        self.videoDataOutput = AVCaptureVideoDataOutput()
//        self.videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global())
//        self.session?.addOutput(self.videoDataOutput!)

        // 6、添加摄像设备输入流到会话对象
        self.session?.addInput(deviceInput)

        // 7、设置数据输出类型(如下设置为条形码和二维码兼容)，需要将数据输出添加到会话后，才能指定元数据类型，否则会报错
        self.metadataOutput?.metadataObjectTypes = [.qr, .code128]

        // 8、实例化预览图层, 用于显示会话对象
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: self.session!)
        // 保持纵横比；填充层边界
        self.videoPreviewLayer?.videoGravity = .resizeAspectFill
        var frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        switch self.searchType {
        case .normal:
            break
        default:
            frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - (302 + ZCScanViewController.keyWindowSafeAreaBootom()))
        }
        self.videoPreviewLayer?.frame = frame
        self.videoPreview.layer.insertSublayer(self.videoPreviewLayer!, at: 0)
        self.view.insertSubview(self.videoPreview, at: 0)
        // 9、开始扫描
        self.startScan()
    }
    
    private static func keyWindowSafeAreaBootom() -> CGFloat {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .safeAreaInsets.bottom ?? 0
        } else {
            return UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        }
    }
    
    /// 申请权限
    func requestAuthorization(sucess: (() -> Void)?) {
        if case .recognizeQRCode = self.searchType {
            return
        }
        // 1、 获取摄像设备
        guard AVCaptureDevice.default(for: .video) != nil else {
            print("未检测到您的摄像头, 请在真机上测试")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                sucess?()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        sucess?()
                    } else {
                        self?.backAction()
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.backAction()
            }
        }
    }
}

// MARK: 相册选取图获取二维码
extension ZCScanViewController {
    func photosAction() {
        self.isPhotoMode = true
        self.scanningline.isHidden = true
        self.stopScan()
        if let albumClickBlock = self.albumClickBlock {
            albumClickBlock {[weak self] image in
                guard let `self` = self else { return }
                self.recognizeQRCode(img: image)
            }
        } else {
            let imgeBlock: (UIImage?) -> Void = {  [weak self] img in
                guard let `self` = self else { return }
                self.recognizeQRCode(img: img)
            }
            let dismissBlock = {
                self.isPhotoMode = false
                DispatchQueue.main.async {
                    self.requestAuthorization { [weak self] in
                        guard let `self` = self else { return }
                        self.scanSession()
                    }
                    self.startScan()
                }
            }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            self.present(picker, animated: true, completion: nil)

            // Store blocks for use in delegate methods
            objc_setAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.imgeBlock, imgeBlock, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            objc_setAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.dismissBlock, dismissBlock, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /// 识别二维码
    private func recognizeQRCode(img: UIImage?) {
        let iv = UIImageView()
        iv.backgroundColor = .black
        iv.contentMode = .scaleAspectFit
        iv.image = img
        iv.bounds = self.view.bounds
        let displayImg = UIImage.generateByLayer(layer: iv.layer)
        self.selectIV.image = displayImg
        self.view.addSubview(self.selectIV)
        self.selectIV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.selectIV.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.selectIV.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.selectIV.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.selectIV.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        self.showLoading()
        DispatchQueue.global().async {
            let qrcodeImg = img?.grayImage()
            
            DispatchQueue.main.async {
                self.hideLoading()
                self.selectIV.removeFromSuperview()
                iv.image = qrcodeImg
                let screenImg = UIImage.generateByLayer(layer: iv.layer)
                
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                guard let screenCg = screenImg?.grayImage()?.cgImage else {
                    self.isPhotoMode = false
                    self.startScan()
                    return
                }

                let ciImage = CIImage(cgImage: screenCg)
                guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] else {
                    self.isPhotoMode = false
                    self.startScan()
                    return
                }

                // 坐标转换（CIImage 为左下原点，UIKit 为左上原点）
                let ciImageSize = ciImage.extent.size
                let displaySize = self.view.bounds.size

                let scaleX = displaySize.width / ciImageSize.width
                let scaleY = displaySize.height / ciImageSize.height
                let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

                // 由于 CoreImage 坐标是左下角原点，而 UIKit 是左上角，所以需要翻转 Y 坐标
                let flip = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -ciImageSize.height)

                let finalTransform = flip.concatenating(transform)

                let transformedFeatures = features.map { feature -> QrcodeResultModel in
                    let transformedBounds = feature.bounds.applying(finalTransform)
                    return QrcodeResultModel(codeStr: feature.messageString,
                                             codeFrame: transformedBounds)
                }

                DispatchQueue.main.async {
                    self.scanningline.isHidden = true
                    self.stopScan()
                    if !transformedFeatures.isEmpty {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    self.showSelectQrcodeView(tags: transformedFeatures, qrcodeImg: displayImg!)
                }
            }
        }
    }
    
    /// 显示二维码定位结果
    private func showSelectQrcodeView(tags: [QrcodeResultModel], qrcodeImg: UIImage?) {
        self.navBar.isHidden = true
        self.linghtView.isHidden = true
        self.qrCodeResultView = QrcodeSelectView.show(tags: tags, orignQrcodeImage: qrcodeImg,selectedTagBlock: { [weak self] item in
            guard let `self` = self else { return }
            let link = item.codeStr ?? ""
            if qrcodeImg != nil {
                self.isPhotoMode = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                    self.openToVc(link: link)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                    self.openToVc(link: link)
                }
            }
            self.navBar.isHidden = false
            self.linghtView.isHidden = false
        }, backBlock: { [weak self] in
            guard let `self` = self else { return }
            if case .recognizeQRCode = self.searchType {
                self.backAction()
            } else {
                if qrcodeImg != nil {
                    self.isPhotoMode = false
                }
                self.navBar.isHidden = false
                self.linghtView.isHidden = false
                self.startScan()
            }
        }, onView: self.view)
    }
    
    private func openToVc(link: String) {
        if let result = self.resultBlock {
            result(link)
        }
    }
}

// MARK: 扫到二维码结果回调
extension ZCScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard self.isScanning else { return }
        self.isScanning = false
        if metadataObjects.count > 0 {
            DispatchQueue.main.async(execute: {
                self.doScanResult(metadataObjects: metadataObjects)
            })
        } else {
            print("[scan] 暂未识别出扫描的二维码")
        }
    }

    private func doScanResult(metadataObjects: [AVMetadataObject]) {
        self.scanningline.isHidden = true
        self.stopScan()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var tags: [QrcodeResultModel] = []
        for value in metadataObjects {
            if let code: AVMetadataMachineReadableCodeObject = self.videoPreviewLayer?.transformedMetadataObject(for: value) as? AVMetadataMachineReadableCodeObject {
                let bounds = code.bounds
                let strValue = code.stringValue
                tags.append(QrcodeResultModel(codeStr: strValue, codeFrame: bounds))
            }
        }
        self.showSelectQrcodeView(tags: tags, qrcodeImg: nil)
    }
}


// MARK: - UIImagePickerControllerDelegate
private struct ZCScanViewControllerAssociatedKeys {
    static var imgeBlock = "imgeBlock"
    static var dismissBlock = "dismissBlock"
}

extension ZCScanViewController {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[.originalImage] as? UIImage
        if let imgeBlock = objc_getAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.imgeBlock) as? (UIImage?) -> Void {
            imgeBlock(image)
        }
        // Remove block after use
        objc_setAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.imgeBlock, nil, .OBJC_ASSOCIATION_ASSIGN)
        objc_setAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.dismissBlock, nil, .OBJC_ASSOCIATION_ASSIGN)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        if let dismissBlock = objc_getAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.dismissBlock) as? () -> Void {
            dismissBlock()
        }
        // Remove block after use
        objc_setAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.imgeBlock, nil, .OBJC_ASSOCIATION_ASSIGN)
        objc_setAssociatedObject(self, &ZCScanViewControllerAssociatedKeys.dismissBlock, nil, .OBJC_ASSOCIATION_ASSIGN)
    }
}
