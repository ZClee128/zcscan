# zcscan

[![CI Status](https://img.shields.io/travis/18162711/zcscan.svg?style=flat)](https://travis-ci.org/18162711/zcscan)
[![Version](https://img.shields.io/cocoapods/v/zcscan.svg?style=flat)](https://cocoapods.org/pods/zcscan)
[![License](https://img.shields.io/cocoapods/l/zcscan.svg?style=flat)](https://cocoapods.org/pods/zcscan)
[![Platform](https://img.shields.io/cocoapods/p/zcscan.svg?style=flat)](https://cocoapods.org/pods/zcscan)

## 简介

zcscan 是一个基于 Swift 的二维码扫描组件，支持自定义 UI 和相册选择，集成简单，扩展性强。

## 安装

### CocoaPods

```ruby
pod 'zcscan'
```

### Swift Package Manager

你可以通过 SPM 集成，在 Xcode 的菜单栏选择 `File > Add Packages...`，输入：

```
https://github.com/你的GitHub用户名/zcscan.git
```

或在 `Package.swift` 里添加依赖：

```swift
.package(url: "https://github.com/你的GitHub用户名/zcscan.git", from: "1.0.0")
```

在 Podfile 添加后，执行 `pod install`。

## 快速开始

### 1. 基本用法

在你的 ViewController 中导入：

```swift
import zcscan
```

#### 方式一：直接 present 内置扫描页面

```swift
let vc = ZCScanViewController.present(fromVC: self, albumClickBlock: nil, resultBlock: { link in
    // 返回的是选择的二维码信息，这里处理自己的业务逻辑
    print("link===>>\(link)")
})
```

#### 方式二：自定义相册选择（push/present 都支持）

```swift
vc = ZCScanViewController.push(fromVC: self, albumClickBlock: { seletPhoto in
    ZLPhotoConfiguration.default().maxSelectCount = 1
    ZLPhotoConfiguration.default().allowEditImage = false
    ZLPhotoConfiguration.default().allowSelectVideo = false
    ZLPhotoConfiguration.default().allowTakePhotoInLibrary = false
    let picker = ZLPhotoPicker()
    picker.selectImageBlock = { results, isOriginal in
        if let img = results.first?.image {
            seletPhoto(img)
        }
    }
    picker.cancelBlock = {
        // 取消回调
    }
    if let vc {
        picker.showPhotoLibrary(sender: vc)
    }
}, resultBlock: { link in
    print("link===>>\(link)")
})
```

### 2. 配置自定义 UI

zcscan 支持高度自定义 UI，所有属性均为公开属性，可灵活调整。例如：

```swift
let config = ZCScanManager.shared.conifg
config.selectQrcodeBtnImage = UIImage(named: "qrcode_arrow")
config.scanninglineImage = UIImage(named: "scan_line")
// 更多配置项请参考 ScanConfig.swift
```

## 示例代码

```swift
@IBAction func openScan(_ sender: Any) {
    let config = ZCScanManager.shared.conifg
    config.selectQrcodeBtnImage = UIImage(named: "qrcode_arrow")
    config.scanninglineImage = UIImage(named: "scan_line")
    let vc = ZCScanViewController.present(fromVC: self, albumClickBlock: nil, resultBlock: { link in
        // 返回二维码内容
        print("link===>>\(link)")
    })
}
```

更多用法请参考 Example 工程中的 ViewController.swift。

## 作者

ZClee, 876231865@qq.com

## License

zcscan is available under the MIT license. See the LICENSE file for more info.
