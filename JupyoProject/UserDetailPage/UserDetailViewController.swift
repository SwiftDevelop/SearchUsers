//
//  UserDetailViewController.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/11/03.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices

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
            userLikeButton.isSelected = true
        }
        
        // 사용자 상세정보
        getUserDetailData()
    }
    
    // MARK: Actions
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func likeButtonAction(_ sender: UIButton) {
        guard var likeUser = AppUserDefaults().get(.likeUser) as? [[String: Any]] else { return }
        
        if sender.isSelected {
            // 좋아요 선택 되어 있을 경우, 선택 해제
            
            sender.isSelected = false
            sender.setImage(UIImage(named: "LikeOff"), for: .normal)
            
            // 사용자 데이터 삭제
            for i in 0..<likeUser.count {
                if likeUser[i]["login"] as? String == userData["login"] as? String {
                    likeUser.remove(at: i)
                    break
                }
            }
            
            
        } else {
            // 좋아요 선택 해제 되어 있을 경우, 선택
            
            sender.isSelected = true
            sender.setImage(UIImage(named: "LikeOn"), for: .normal)
            
            // 중복 이름 확인
            let checkValue = likeUser.filter {
                $0["login"] as? String == userData["login"] as? String
            }
            
            // 리스트에서 좋아요 선택 확인을 위해 값 추가
            userData["like"] = "Y"
            
            // 중복 이름이 없을 경우 사용자 추가
            if checkValue.count == 0 {
                likeUser.append(userData)
            }
        }
        
        // 데이터 저장
        AppUserDefaults().set(likeUser, key: .likeUser)
    }
    
    @IBAction func followButtonAction(_ sender: UIButton) {
        if sender.tag == 0 {
            // 팔로우
            sender.tag = 1
            sender.backgroundColor = .blue
            
        } else {
            // 팔로우 해제
            sender.tag = 0
            sender.backgroundColor = .lightGray
        }
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
                
                // Git
                if let git = json["html_url"] as? String {
                    let dic = ["title": "Git", "sub": git]
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
        case "Followers", "Subscriptions": // 팔로워 리스트
            guard let vc = storyboard.instantiateViewController(withIdentifier: "FollowersViewController") as? FollowersViewController else { fatalError() }
            
            // Title
            vc.titleString = title
            
            // URL
            if title == "Followers" {
                guard let url = userData["followers_url"] as? String else { return }
                vc.followerUrl = url
            } else {
                guard let url = userData["subscriptions_url"] as? String else { return }
                vc.followerUrl = url
            }
            
            navigationController?.pushViewController(vc, animated: true)
            
        case "Blog", "Git": // 사용자 블로그
            guard let address = userInfoList[indexPath.row]["sub"] as? String else { return }
            guard let url = URL(string: address) else { return }
            let safariView = SFSafariViewController(url: url)
            present(safariView, animated: true, completion: nil)
            
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
