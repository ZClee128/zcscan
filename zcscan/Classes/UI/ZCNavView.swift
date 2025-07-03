//
//  ZCNavView.swift
//  zcscan
//
//  Created by lzc on 2025/7/3.
//

import Foundation
import UIKit

public class ZCNavView: UIView {
    /// 背景颜色
    public let bgView = UIView()
    /// 状态栏
    public let topView = UIView()
    /// 导航栏
    public let bar = UIView()
    /// 返回按钮
    public var backItem = UIButton()
    /// 标题
    public let titleLabel = UILabel()
    /// 底部自定义view
    public let customView = UIView()
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func keyWindowSafeAreaTop() -> CGFloat {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .safeAreaInsets.top ?? 0
        } else {
            return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        }
    }
    
    public func initUI() {
        self.backgroundColor = .clear

        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.spacing = 0
        vStackView.alignment = .center

        self.bgView.backgroundColor = .clear
        self.addSubview(self.bgView)
        self.bgView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bgView.topAnchor.constraint(equalTo: self.topAnchor),
            self.bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.bgView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.bgView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        self.bgView.addSubview(vStackView)
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStackView.topAnchor.constraint(equalTo: self.bgView.topAnchor),
            vStackView.bottomAnchor.constraint(equalTo: self.bgView.bottomAnchor),
            vStackView.leadingAnchor.constraint(equalTo: self.bgView.leadingAnchor),
            vStackView.trailingAnchor.constraint(equalTo: self.bgView.trailingAnchor),
            vStackView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        ])

        self.topView.backgroundColor = .clear
        vStackView.addArrangedSubview(self.topView)
        self.topView.translatesAutoresizingMaskIntoConstraints = false
        self.topView.heightAnchor.constraint(equalToConstant: ZCNavView.keyWindowSafeAreaTop()).isActive = true

        let barHeight: CGFloat = 44
        self.bar.backgroundColor = .clear
        vStackView.addArrangedSubview(self.bar)
        self.bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bar.heightAnchor.constraint(equalToConstant: barHeight),
            self.bar.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        ])

        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = .white
        self.bar.addSubview(self.titleLabel)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.titleLabel.centerXAnchor.constraint(equalTo: self.bar.centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.bar.centerYAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.bar.leadingAnchor, constant: 90),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.bar.trailingAnchor, constant: -90)
        ])

        let image = UIImage(named: "navigation_back", in: Bundle.zcscanBundle, compatibleWith: nil)
        self.backItem.setImage(image, for: .normal)
        self.bar.addSubview(self.backItem)
        self.backItem.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.backItem.leadingAnchor.constraint(equalTo: self.bar.leadingAnchor, constant: 12),
            self.backItem.centerYAnchor.constraint(equalTo: self.bar.centerYAnchor),
            self.backItem.widthAnchor.constraint(equalToConstant: 24),
            self.backItem.heightAnchor.constraint(equalToConstant: 24)
        ])

        vStackView.addArrangedSubview(self.customView)
        self.customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.customView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        ])
        self.customView.isHidden = true
    }
    
    /// 返回界面高度
    /// - returns: 界面高度
    public static func viewHeight() -> CGFloat {
        let statusBarHeight = keyWindowSafeAreaTop()
        return statusBarHeight + 44
    }
}
