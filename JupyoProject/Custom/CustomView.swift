//
//  CustomView.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/11/03.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit

extension UIView {
    
    func setLayer(withCorner radius: CGFloat, borderColor: UIColor? = nil, borderWidth: CGFloat = 0) {
        self.layer.borderColor = borderColor?.cgColor
        self.layer.borderWidth = borderWidth
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
}
