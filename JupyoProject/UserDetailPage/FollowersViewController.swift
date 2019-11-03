//
//  FollowersViewController.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/11/03.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit
import Alamofire

class FollowersViewController: UIViewController {

    @IBOutlet weak var naviView: UIView!
    
    // 검색 탭 뷰
    lazy var listView: ListView = {
        let view = Bundle.main.loadNibNamed("ListView", owner: self, options: nil)?.first as! ListView
        view.tab = .search
        view.resultLabel.text = "팔로워가 없습니다"
        return view
    }()
    
    var followerUrl = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ListView
        listView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(listView)
        
        // List AutoLayout
        listView.topAnchor.constraint(equalTo: naviView.bottomAnchor).isActive = true
        listView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        listView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        listView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        // Get Followers
        AF.request(followerUrl).response { response in
            switch response.result {
            case let .success(data):
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
                
                self.listView.getListData(json)
                
            case let .failure(error):
                debugPrint(error)
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
}
