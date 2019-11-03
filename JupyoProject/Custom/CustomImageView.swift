//
//  CustomImageView.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/11/03.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImageView {
    
    func setImage(_ address: String?) {
        guard let address = address else { return self.image = nil }
        guard let url = URL(string: address) else { return }
        let resource = ImageResource(downloadURL: url, cacheKey: address)
        self.kf.setImage(
            with: resource,
            placeholder: UIImage(named: "UserDefault"),
            options: [.transition(ImageTransition.fade(0.3))])
    }
    
}
