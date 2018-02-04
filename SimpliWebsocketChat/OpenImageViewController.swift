//
//  OpenImageViewController.swift
//  SimpliWebsocketChat
//
//  Created by Murat Zhakupov on 04.02.2018.
//  Copyright © 2018 Murat Zhakupov. All rights reserved.
//

import UIKit

class OpenImageViewController: UIViewController {
    
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.bounds = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
        imageView.frame.origin = CGPoint(x: 0, y: 0)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
