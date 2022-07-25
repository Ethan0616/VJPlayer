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
        // http://vfx.mtime.cn/Video/2019/03/13/mp4/190313094901111138.mp4 // 阿拉丁
//        guard let urlPath =  URL.init(string: "http://vfx.mtime.cn/Video/2019/03/13/mp4/190313094901111138.mp4") else {
        let mp4Urls = ["http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/21/mp4/190321153853126488.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319222227698228.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319212559089721.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/18/mp4/190318214226685784.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319104618910544.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319125415785691.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/17/mp4/190317150237409904.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/14/mp4/190314223540373995.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/14/mp4/190314102306987969.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/13/mp4/190313094901111138.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/12/mp4/190312143927981075.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/12/mp4/190312083533415853.mp4",
                       "http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4"]
        guard let urlPath =  URL.init(string: mp4Urls[Int(arc4random()) % (mp4Urls.count - 1)]) else {
            let path : String = Bundle.main.path(forResource: "1653903243735430", ofType: "mp4") ?? ""
            let url = URL.init(fileURLWithPath: path)
            return url
        }
        return urlPath
    }
}










