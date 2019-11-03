//
//  ListView.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/10/27.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit

enum Tab {
    case search, like
}

protocol ListViewDelegate {
    func loadNextPageData()
    func refreshData()
    func push(_ vc: UIViewController)
}

class ListView: UIView {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // RefreshControl for TableView
    @objc let refreshControl = UIRefreshControl()
    
    var delegate: ListViewDelegate? = nil
    
    // 사용자 검색 결과 데이터
    var listData = [[String: Any]]()
    var tab: Tab = .search
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        activityIndicator.isHidden = true

        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ListViewCell", bundle: nil), forCellReuseIdentifier: "ListViewCell")
        tableView.tableFooterView = UIView()
        
        refreshControl.addTarget(self, action: #selector(refreshListData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
}

// MARK: Functions

extension ListView: ListViewCellDelegate {
    
    // 데이터 받아오기
    func getListData(_ data: [[String: Any]]) {
        // 애니메이션 종료
        animateActivityIndicator(false, result: tab == .search ? "검색 결과가 없습니다" : "'좋아요' 사용자가 없습니다")
        refreshControl.endRefreshing()
        
        // 데이터 추가 및 표시
        guard data.count != 0 else { return }
        listData += data
        tableView.isHidden = listData.count == 0 ? true : false
        tableView.reloadData()
    }
    
    // 데이터 초기화
    func resetListData() {
        listData = [[String: Any]]()
        tableView.isHidden = true
        tableView.reloadData()
    }
    
    // 데이터 리로드
    @objc func refreshListData(_ refresh: UIRefreshControl) {
        resetListData()
        delegate?.refreshData()
    }
    
    // 좋아요 선택 시 선택 여부 표시를 위해 데이터 값 추가 및 변경
    func selectLike(_ cell: ListViewCell) {
        
        // 좋아요를 선택한 셀의 IndexPath
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tab == .search {
            // 검색 탭
            
            // 이전 좋아요 저장 데이터 불러오기
            var favorUser = AppUserDefaults().get(.likeUser) as? [[String: Any]] ?? [[String: Any]]()
            
            // 좋아요 선택 해제
            if let like = listData[indexPath.row]["like"] as? String, like == "Y" {
                
                listData[indexPath.row]["like"] = "N"
                
                // 저장 된 사용자 중에 해당 데이터 제거
                for i in 0..<favorUser.count {
                    if favorUser[i]["login"] as? String == listData[indexPath.row]["login"] as? String {
                        favorUser.remove(at: i)
                        break
                    }
                }
                
            } else {
                // 좋아요 선택
                
                listData[indexPath.row]["like"] = "Y"
                
                // 중복 이름 확인
                let checkValue = favorUser.filter {
                    $0["login"] as? String == listData[indexPath.row]["login"] as? String
                }
                
                // 중복 이름이 없을 경우 사용자 추가
                if checkValue.count == 0 {
                    favorUser.append(listData[indexPath.row])
                }
            }
            
            // 좋아요 사용자 데이터 저장
            AppUserDefaults().set(favorUser, key: .likeUser)
            
        } else {
            // 좋아요 탭
            
            // 좋아요 선택 해제
            listData.remove(at: indexPath.row)
            tableView.isHidden = listData.count == 0 ? true : false
            
            // 좋아요 사용자 데이터 저장
            AppUserDefaults().set(listData, key: .likeUser)
        }
        
        // 테이블뷰 리로드
        tableView.reloadData()
    }
    
    // 검색 시 애니메이션 설정
    func animateActivityIndicator(_ animate: Bool, result: String) {
        resultLabel.text = result
        activityIndicator.isHidden = !animate
        
        if animate {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
    }
    
}

// MARK: TableView

extension ListView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListViewCell", for: indexPath) as? ListViewCell else { fatalError() }
        
        // Delegate
        cell.delegate = self
        
        // Data
        let data = listData[indexPath.row]
        
        // Image
        cell.userImageView.setImage(data["avatar_url"] as? String)
        
        // Title
        cell.userNameLabel.text = data["login"] as? String
        
        // Score
        let score = data["score"] as? Double ?? 0.0
        cell.userScoreLabel.text = "Score: \(score)"
        
        // Like
        if let like = data["like"] as? String, like == "Y" {
            cell.likeButton.setImage(UIImage(named: "LikeOn"), for: .normal)
        } else {
            cell.likeButton.setImage(UIImage(named: "LikeOff"), for: .normal)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 마지막 리스트 일 때 다음 페이지 데이터 불러오기
        if indexPath.row == listData.count - 1 {
            delegate?.loadNextPageData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "UserDetail", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "UserDetailViewController") as? UserDetailViewController else { fatalError() }
        guard let url = listData[indexPath.row]["url"] as? String else { return }
        vc.userData = listData[indexPath.row]
        delegate?.push(vc)
    }
}

// MARK: TableViewCell

protocol ListViewCellDelegate {
    func selectLike(_ cell: ListViewCell)
}

class ListViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    var delegate: ListViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.setLayer(withCorner: 24)
    }
 
    // MARK: Actions
    
    @IBAction func likeButtonAction(_ sender: UIButton) {
        delegate?.selectLike(self)
    }
    
}
