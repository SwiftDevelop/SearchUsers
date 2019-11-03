//
//  UserDetailViewController.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/11/03.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit
import Alamofire

class UserDetailViewController: UIViewController {

    @IBOutlet weak var userLoginLabel: UILabel!
    @IBOutlet weak var userLikeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var userData = [String: Any]()
    var userInfoList = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 좋아요 선택 표시
        if let like = userData["like"] as? String {
            let img = like == "Y" ? UIImage(named: "LikeOn") : UIImage(named: "LikeOff")
            userLikeButton.setImage(img, for: .normal)
        }
        
        // 사용자 상세정보
        getUserDetailData()
    }
    
    // MARK: Actions
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

// MARK: Functions

extension UserDetailViewController {
    
    func getUserDetailData() {
        guard let url = userData["url"] as? String else {
            let alert = UIAlertController(title: "알림", message: "사용자 정보가 없습니다", preferredStyle: .alert)
            let action = UIAlertAction(title: "확인", style: .default) { (_) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        AF.request(url).response { response in
            switch response.result {
            case let .success(data):
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                print(json)
                
                // Login
                self.userLoginLabel.text = json["login"] as? String
                
                // Profile
                if let avatarImg = json["avatar_url"] as? String,
                    let name = json["name"] as? String {
                    let dic = ["img": avatarImg, "title": name]
                    self.userInfoList.append(dic)
                }
                
                // Email
                if let email = json["email"] as? String {
                    let dic = ["title": "Email", "sub": email]
                    self.userInfoList.append(dic)
                }
                
                // Followers
                if let followers = json["followers"] as? Int {
                    let dic = ["title": "Followers", "sub": "\(followers)"]
                    self.userInfoList.append(dic)
                }
                
                // Blog
                if let blog = json["blog"] as? String {
                    let dic = ["title": "Blog", "sub": blog]
                    self.userInfoList.append(dic)
                }
                
                // Location
                if let location = json["location"] as? String {
                    let dic = ["title": "Location", "sub": location]
                    self.userInfoList.append(dic)
                }
                
                // Company
                if let company = json["company"] as? String {
                    let dic = ["title": "Company", "sub": company]
                    self.userInfoList.append(dic)
                }
                
                // Subscriptions
                if json["subscriptions_url"] as? String != nil {
                    let dic = ["title": "Subscriptions"]
                    self.userInfoList.append(dic)
                }
                
                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.tableView.reloadData()
                self.tableView.tableFooterView = UIView()
                
            case let .failure(error):
                debugPrint(error)
            }
        }
    }
    
}

// MARK: TableView

extension UserDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userInfoList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailCell") as? UserDetailCell else { fatalError() }
        
        // Data
        let data = userInfoList[indexPath.row]
        
        // Contents
        if let img = data["img"] as? String {
            cell.thumbImageView.setImage(img)
            cell.thumbImageView.isHidden = false
            cell.thumbImageViewWidth.constant = 48.0
            cell.thumbImageViewLeading.constant = 16
        } else {
            cell.thumbImageView.isHidden = true
            cell.thumbImageViewWidth.constant = 0
            cell.thumbImageViewLeading.constant = 0
        }
        
        cell.titleLable.text = data["title"] as? String
        cell.subTitleLabel.text = data["sub"] as? String
        
        // Follow Button
        cell.followButton.isHidden = indexPath.row == 0 ? false : true
        
        // Arrow ImageView
        cell.arrowImageView.isHidden = indexPath.row == 0 ? true : false
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let title = userInfoList[indexPath.row]["title"] as? String else { return }
        let storyboard = UIStoryboard(name: "UserDetail", bundle: nil)
        switch title {
        case "Followers":
            guard let vc = storyboard.instantiateViewController(withIdentifier: "FollowersViewController") as? FollowersViewController else { fatalError() }
            guard let url = userData["followers_url"] as? String else { return }
            vc.followerUrl = url
            navigationController?.pushViewController(vc, animated: true)
            
        default:
            break
        }
    }
}

// MARK: UserDetailCell

class UserDetailCell: UITableViewCell {
    
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var thumbImageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var thumbImageViewLeading: NSLayoutConstraint!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbImageView.setLayer(withCorner: 24)
        followButton.setLayer(withCorner: 8)
    }
}
