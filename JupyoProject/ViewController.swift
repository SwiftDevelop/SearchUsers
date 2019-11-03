//
//  ViewController.swift
//  JupyoProject
//
//  Created by 장주표 on 2019/10/27.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit
import Alamofire

let screenWidth = UIScreen.main.bounds.width    // 화면 넓이
let screenHeight = UIScreen.main.bounds.height  // 화면 높이

class ViewController: UIViewController {

    // 상단 검색뷰
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchDeleteButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    // 상단 검색 탭
    @IBOutlet weak var searchTabButton: UIButton!
    @IBOutlet weak var searchTabUnderLine: UIView!
    
    // 상단 좋아요 탭
    @IBOutlet weak var likeTabButton: UIButton!
    @IBOutlet weak var likeTabUnderLine: UIView!
    
    // 상단 탭 구분선
    @IBOutlet weak var tabSeparateView: UIView!
    
    // 탭 페이지용 스크롤뷰
    var scrollView = UIScrollView()
    
    // 검색 탭 뷰
    lazy var searchTabView: ListView = {
        let view = Bundle.main.loadNibNamed("ListView", owner: self, options: nil)?.first as! ListView
        view.delegate = self
        view.tab = .search
        view.resultLabel.text = "검색 결과가 없습니다"
        return view
    }()
    
    // 좋아요 탭 뷰
    lazy var likeTabView: ListView = {
        let view = Bundle.main.loadNibNamed("ListView", owner: self, options: nil)?.first as! ListView
        view.delegate = self
        view.tab = .like
        view.resultLabel.text = "'좋아요' 사용자가 없습니다"
        
        // 저장 된 좋아요 선택 된 사용자 불러오기
        if let data = AppUserDefaults().get(.likeUser) as? [[String: Any]] {
            view.getListData(data)
        }
        
        return view
    }()
    
    var searchUsersList = [[String: Any]]()
    var word: String = ""   // 검색어
    var page: Int = 1       // 페이지
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 검색뷰 모서리 둥글게
        searchView.layer.cornerRadius = 20
        searchView.layer.masksToBounds = true
        
        // 검색 텍스트필드 Delegate
        searchTextField.delegate = self
        
        // 검색어 삭제 버튼 숨김
        searchDeleteButton.isHidden = true
        
        // 스크롤뷰 생성 및 설정
        setScrollView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 상세페이지에서 돌아왔을 경우 좋아요 체크
        checkLikeSelected()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 추가 된 탭 뷰의 각각 좌표 설정
        searchTabView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: scrollView.frame.height)
        likeTabView.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: scrollView.frame.height)
    }

    // MARK: Actions
    
    @IBAction func searchTextFieldAction(_ sender: UITextField) {
        guard let text = sender.text else { return }
        searchDeleteButton.isHidden = text.isEmpty
    }
    
    @IBAction func searchDeleteButtonAction(_ sender: UIButton) {
        sender.isHidden = true
        searchTextField.text = ""
        
        // 검색어 삭제 시 데이터 초기화
        searchTabView.resetListData()
        searchUsersList.removeAll()
    }
    
    @IBAction func searchButtonAction(_ sender: UIButton) {
        // 키보드 숨기기
        searchTextField.resignFirstResponder()
        
        // 데이터 초기화
        searchTabView.resetListData()
        searchUsersList.removeAll()
        
        // 검색 탭으로 이동
        tabButtonAction(searchTabButton)
        
        // 검색어 확인
        guard let text = searchTextField.text?.trimmingCharacters(in: .whitespaces), text != "" else {
            // 내용이 없을 시 검색창 초기화
            searchTextField.text = ""
            searchDeleteButton.isHidden = true
            return
        }
        
        // ActivityIndicator Start Animate
        searchTabView.animateActivityIndicator(true, result: "잠시만 기다려 주세요")
        
        // 새 데이터 불러오기
        word = text
        page = 1
        searchingUser(word, page: 1)
    }
    
    @IBAction func tabButtonAction(_ sender: UIButton) {
        if sender == searchTabButton {
            // 검색 탭 선택
            selectTab(withButton: searchTabButton, line: searchTabUnderLine, select: true)
            selectTab(withButton: likeTabButton, line: likeTabUnderLine, select: false)
            
            // 검색 탭으로 스크롤뷰 이동
            scrollView.setContentOffset(.zero, animated: true)
            
            // 좋아요 선택 체크
            checkLikeSelected()
            
        } else {
            // 좋아요 탭 선택
            selectTab(withButton: searchTabButton, line: searchTabUnderLine, select: false)
            selectTab(withButton: likeTabButton, line: likeTabUnderLine, select: true)
            
            // 좋아요 탭으로 스크롤뷰 이동
            scrollView.setContentOffset(CGPoint(x: screenWidth, y: 0), animated: true)
            
            // 좋아요 사용자 데이터 불러오기
            guard let likeUser = AppUserDefaults().get(.likeUser) as? [[String: Any]] else { return }
            likeTabView.resetListData()
            likeTabView.getListData(likeUser)
        }
    }
    
}

// MARK: Functions

extension ViewController: ListViewDelegate {
    
    // 상단 탭 버튼 선택
    func selectTab(withButton button: UIButton, line: UIView, select: Bool) {
        button.tag = select ? 1 : 0
        button.setTitleColor(select ? .darkGray : .lightGray, for: .normal)
        line.backgroundColor = select ? .darkGray : .white
    }
    
    // 스크롤뷰 생성 및 설정
    func setScrollView() {
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize.width = screenWidth * 2
        view.addSubview(scrollView)
        
        // 스크롤뷰 AutoLayout
        scrollView.topAnchor.constraint(equalTo: tabSeparateView.bottomAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        // 스크롤뷰에 탭 뷰 추가
        scrollView.addSubview(searchTabView)
        scrollView.addSubview(likeTabView)
    }
    
    // 검색어 데이터 불러오기
    func searchingUser(_ word: String, page: Int) {
        
        // 사용자 검색
        let url = "https://api.github.com/search/users?q=\(word)&page=\(page)"
        AF.request(url).response { response in
            switch response.result {
            case let .success(data):
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                
                if let items = json["items"] as? [[String: Any]] {
                    
                    // 사용자 리스트 저장
                    self.searchUsersList += items
                    
                    // 좋아요 체크 후 전달
                    self.checkLikeSelected()
                    
                } else {
                    self.searchTabView.getListData([[String: Any]]())
                }
            case let .failure(error):
                debugPrint(error)
                self.searchTabView.getListData([[String: Any]]())
            }
        }
    }
    
    // 데이터를 불러오거나 상세페이지에서 나왔을 경우 '좋아요' 의 선택 변동 사항 적용
    func checkLikeSelected() {
        // 좋아요 선택 된 사용자 리스트
        let likeUser = AppUserDefaults().get(.likeUser) as? [[String: Any]] ?? [[String: Any]]()
        
        if searchTabButton.tag == 1 {
            // 좋아요 선택 확인
            for i in 0..<searchUsersList.count {
                // 중복 확인
                let check = likeUser.filter {
                    $0["login"] as? String == searchUsersList[i]["login"] as? String
                }
                
                // 중복 된 사용자가 있을 경우 좋아요 선택 처리
                if check.count != 0 {
                    searchUsersList[i]["like"] = "Y"
                } else {
                    // 값이 없을 경우에는 선택 해제 처리
                    searchUsersList[i]["like"] = "N"
                }
            }
            
            // 검색 탭
            searchTabView.getListData(searchUsersList)
            
        } else {
            // 좋아요 탭
            likeTabView.getListData(likeUser)
        }
    }
    
    // 다음 페이지 데이터 불러오기
    func loadNextPageData() {
        page += 1
        searchingUser(word, page: page)
    }
    
    // 데이터 리로드
    func refreshData() {
        // 사용자 검색 리스트 모두 제거
        searchUsersList.removeAll()
        
        // 첫 페이지 데이터 다시 불러오기
        page = 1
        searchingUser(word, page: 1)
    }
    
    // Push from Tab Views
    func push(_ vc: UIViewController) {
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: TextField

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchButtonAction(searchButton)
        return true
    }
    
}

// MARK: ScrollView

extension ViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        // 탭 페이지 위치
        let x = scrollView.contentOffset.x / scrollView.frame.width
        
        if x == 0.0 {
            // 검색 탭 선택
            selectTab(withButton: searchTabButton, line: searchTabUnderLine, select: true)
            selectTab(withButton: likeTabButton, line: likeTabUnderLine, select: false)
        } else {
            // 좋아요 탭 선택
            selectTab(withButton: searchTabButton, line: searchTabUnderLine, select: false)
            selectTab(withButton: likeTabButton, line: likeTabUnderLine, select: true)
        }
    }
    
}

