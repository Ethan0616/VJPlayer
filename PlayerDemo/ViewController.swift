//
//  ViewController.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/4.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableview.dequeueReusableCell(withIdentifier: "CustomTableViewCellIdentifier") as? CustomTableViewCell else {
            return UITableViewCell()
        }
        
        cell.controller = self
        cell.delegate = self
        return cell
    }
    


    @IBOutlet weak var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableview.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomTableViewCellIdentifier")
    }


}


extension ViewController: CustomTableViewCellProtocol {
    // cell 点击事件
    func imageClicked(_ frame: CGRect) ->URL {
        print("ViewController delegate")
        guard let urlPath =  URL.init(string: "") else {
//        guard let urlPath =  URL.init(string: "http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4") else {
            let path : String = Bundle.main.path(forResource: "1653903243735430", ofType: "mp4") ?? ""
            let url = URL.init(fileURLWithPath: path)
            return url
        }
        return urlPath
    }
}


