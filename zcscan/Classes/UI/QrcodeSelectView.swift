//
//  QrcodeSelectView.swift
//  zcscan
//
//  Created by lzc on 2025/7/3.
//

import Foundation
import UIKit

class QrcodeSelectView: UIView {
    private let bgView = UIView()
    private let tags: [QrcodeResultModel]
    private var orignQrcodeImage: UIImage?
    private var selectedTagBlock:  ((QrcodeResultModel) -> Void)?
    private var backBlock: (() -> Void)?
    
    static func show(tags:[QrcodeResultModel], orignQrcodeImage:UIImage? = nil, selectedTagBlock: ((QrcodeResultModel) -> Void)?, backBlock: (() -> Void)? ,onView: UIView) -> QrcodeSelectView {
        let v = QrcodeSelectView.init(tags: tags, orignQrcodeImage: orignQrcodeImage)
        v.selectedTagBlock = selectedTagBlock
        v.backBlock = backBlock

        onView.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: onView.topAnchor),
            v.bottomAnchor.constraint(equalTo: onView.bottomAnchor),
            v.leadingAnchor.constraint(equalTo: onView.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: onView.trailingAnchor)
        ])
        v.bgView.backgroundColor = .black.withAlphaComponent(0.0)
        UIView.animate(withDuration: 0.25) {
            v.bgView.backgroundColor = .black.withAlphaComponent(0.7)
        }
        return v
    }

    init(tags: [QrcodeResultModel], orignQrcodeImage: UIImage? = nil) {
        self.tags = tags
        self.orignQrcodeImage = orignQrcodeImage
        super.init(frame: .zero)
        self.initUI()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initUI() {
        self.addSubview(self.bgView)
        self.bgView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bgView.topAnchor.constraint(equalTo: self.topAnchor),
            self.bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.bgView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.bgView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        if let img = self.orignQrcodeImage {
            let iv = UIImageView()
            iv.image = img
            iv.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(iv, belowSubview: self.bgView)
            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: self.topAnchor),
                iv.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                iv.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        }

        let isOneCode = self.tags.count == 1

        self.tags.forEach { e in
            if let frame = e.codeFrame {
                let btn = self.getCodeButtonWith(bounds: frame)
                btn.zc.tap(tapBlock: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.selectedTagBlock?(e)
                    self.dismiss(completed: nil)
                })
                self.addSubview(btn)
            }
        }

        if isOneCode, let item = self.tags.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.selectedTagBlock?(item)
                self.dismiss(completed: nil)
            }
        }

        if self.tags.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                YXDToast.show(text: "没检测到二维码")
                self.selectViewDismiss()
            }
        }

        let tipsLb = UILabel()
        tipsLb.textColor = .white
        tipsLb.font = .systemFont(ofSize: 12)
        tipsLb.text = "点击任何一个你想要的二维码"
        tipsLb.numberOfLines = 0
        tipsLb.textAlignment = .center
        self.addSubview(tipsLb)
        tipsLb.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tipsLb.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            tipsLb.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            tipsLb.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        let cancelBtn = UIButton()
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 16)
        self.addSubview(cancelBtn)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: self.topAnchor, constant: 53),
            cancelBtn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            cancelBtn.heightAnchor.constraint(equalToConstant: 22)
        ])
        cancelBtn.zc.tap {[weak self] _ in
            guard let `self` = self else { return }
            self.selectViewDismiss()
        }
    }

    @objc public func selectViewDismiss() {
        self.dismiss(completed: { [weak self] in
            self?.backBlock?()
        })
    }

    private func dismiss(completed: (() -> Void)?) {
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundColor = .black.withAlphaComponent(0.0)
            self.alpha = 0.0
        }, completion: {_ in
            completed?()
            self.removeFromSuperview()
        })
    }

    func getCodeButtonWith(bounds: CGRect) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.frame = bounds
        var rect = btn.frame
        let center = btn.center
        rect.size.width = 40
        rect.size.height = 40
        btn.frame = rect
        btn.center = center
        if let image = ZCScanManager.shared.conifg.selectQrcodeBtnImage {
            btn.setImage(image, for: .normal)
        } else {
            btn.backgroundColor = .green
            btn.layer.cornerRadius = 20
            btn.clipsToBounds = true
            btn.layer.borderColor = UIColor.white.cgColor
            btn.layer.borderWidth = 3
        }
        
        // Add heartbeat animation
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 0.8
        pulse.fromValue = 1.0
        pulse.toValue = 1.2
        pulse.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        btn.layer.add(pulse, forKey: "heartbeat")

        return btn
    }
}
