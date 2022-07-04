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
        
        guard let cell = tableview.dequeueReusableCell(withIdentifier: "CustomTableViewCellIdentifier") else {
            return UITableViewCell()
        }
        
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
    func imageClicked(_ frame: CGRect) {
        
    }
}


