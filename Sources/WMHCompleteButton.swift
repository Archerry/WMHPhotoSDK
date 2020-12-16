//
//  WMHCompleteButton.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/16.
//

import UIKit

class WMHCompleteButton: UIView {
    static let startColor = UIColor(argb: 0xFF6404)
    static let endColor = UIColor(argb: 0xF21C1C)
    var backView : UIView!
    var gradientView : UIView!
    public var titleLbl : UILabel!
    public var actionBtn : UIButton!
    
    public var completeBlock:(() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }
    
    func configureView() {
        backView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        backView.clipsToBounds = true
        backView.layer.cornerRadius = self.frame.size.height / 2
        backView.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        self.addSubview(backView)
                
        gradientView = UIView(frame: CGRect(x: 0, y: 0, width: backView.frame.size.width, height: backView.frame.size.height))
        gradientView.clipsToBounds = true
        gradientView.layer.cornerRadius = backView.frame.size.height / 2
        backView.addSubview(gradientView)
        let colors = [WMHCompleteButton.startColor.cgColor, WMHCompleteButton.endColor.cgColor]
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.colors = colors
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, at: 0)
        
        titleLbl = UILabel(frame: CGRect(x: 0, y: 0, width: backView.frame.size.width, height: backView.frame.size.height))
        titleLbl.text = "完成"
        titleLbl.textColor = .white
        titleLbl.textAlignment = .center
        titleLbl.font = WMHFont(fontSize: 14)
        backView.addSubview(titleLbl)
        
        actionBtn = UIButton(frame: CGRect(x: 0, y: 0, width: backView.frame.size.width, height: backView.frame.size.height))
        actionBtn.backgroundColor = .clear
        actionBtn.addTarget(self, action: #selector(completeAction(sender:)), for: .touchUpInside)
        backView.addSubview(actionBtn)
    }
    
    @objc private func completeAction(sender: Any) {
        completeBlock?()
    }
    
    public func hightLightAction() {
        gradientView.isHidden = false
        titleLbl.textColor = .white
    }
    
    public func normalAction() {
        gradientView.isHidden = true
        titleLbl.textColor = UIColor(white: 1.0, alpha: 0.4)
    }
}
