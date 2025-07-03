//
//  ViewController.swift
//  zcscan
//
//  Created by 18162711 on 07/03/2025.
//  Copyright (c) 2025 18162711. All rights reserved.
//

import UIKit
import zcscan
import ZLPhotoBrowser

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func openScan(_ sender: Any) {
        var vc: ZCScanViewController?
        /// 配置处理, 如果写了就用传入的为准，不写默认使用内部定义的UI图
        /// 其他UI自定义可以自行外部修改，所有都是公开属性，灵活度高
        let conifg = ZCScanManager.shared.conifg
        conifg.selectQrcodeBtnImage = UIImage(named: "qrcode_arrow")
        conifg.scanninglineImage = UIImage(named: "scan_line")
        /// 此处为push弹出，自定义选择相册
        
//        vc = ZCScanViewController.push(fromVC: self, albumClickBlock: { seletPhoto in
//            ZLPhotoConfiguration.default().maxSelectCount = 1
//            ZLPhotoConfiguration.default().allowEditImage = false
//            ZLPhotoConfiguration.default().allowSelectVideo = false
//            ZLPhotoConfiguration.default().allowTakePhotoInLibrary = false
//            let picker = ZLPhotoPicker()
//            picker.selectImageBlock = { results, isOriginal in
//                if let img = results.first?.image {
//                    seletPhoto(img)
//                }
//            }
//            picker.cancelBlock = {
//
//            }
//            if let vc {
//                picker.showPhotoLibrary(sender: vc)
//            }
//        }, resultBlock: { link in
//            print("link===>>\(link)")
//        })

        /// 此处为present弹出，自定义相册选择图片
//        vc = ZCScanViewController.present(fromVC: self, albumClickBlock: { seletPhoto in
//            ZLPhotoConfiguration.default().maxSelectCount = 1
//            ZLPhotoConfiguration.default().allowEditImage = false
//            ZLPhotoConfiguration.default().allowSelectVideo = false
//            ZLPhotoConfiguration.default().allowTakePhotoInLibrary = false
//            let picker = ZLPhotoPicker()
//            picker.selectImageBlock = { results, isOriginal in
//                if let img = results.first?.image {
//                    seletPhoto(img)
//                }
//            }
//            picker.cancelBlock = {
//
//            }
//            if let vc {
//                picker.showPhotoLibrary(sender: vc)
//            }
//        }, resultBlock: { link in
//            print("link===>>\(link)")
//        })
        
        /// 此处为使用内部提供的系统相册选择，push和present处理一样
        vc = ZCScanViewController.present(fromVC: self, albumClickBlock: nil, resultBlock: { link in
                // 返回的是选择的二维码信息，这里处理自己的业务逻辑
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

