/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

class JoinChatViewController: UIViewController {
  let logoImageView = UIImageView()
  let shadowView = UIView()
  let nameTextField = TextField()
}

extension JoinChatViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    let chatVC = ChatViewController()
    if let username = nameTextField.text {
      chatVC.userName = username
    }
    navigationController?.pushViewController(chatVC, animated: true)
    return true
  }
}

class TextField: UITextField {
  
  let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8);
  
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return UIEdgeInsetsInsetRect(bounds, padding)
  }
  
  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return UIEdgeInsetsInsetRect(bounds, padding)
  }
  
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return UIEdgeInsetsInsetRect(bounds, padding)
  }
}

extension JoinChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadViews()
        
        view.addSubview(shadowView)
        view.addSubview(logoImageView)
        view.addSubview(nameTextField)
    }
    
    func loadViews() {
        view.backgroundColor = UIColor(red: 24/255, green: 180/255, blue: 128/255, alpha: 1.0)
        navigationItem.title = "Simple Chat"
        
        logoImageView.image = UIImage(named: "avatar.png")
        logoImageView.layer.cornerRadius = 4
        logoImageView.clipsToBounds = true
        
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowRadius = 5
        shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        shadowView.layer.shadowOpacity = 0.5
        shadowView.backgroundColor = UIColor(red: 24/255, green: 180/255, blue: 128/255, alpha: 1.0)
        
        nameTextField.placeholder = "Enter your username?"
        nameTextField.backgroundColor = .white
        nameTextField.layer.cornerRadius = 4
        nameTextField.delegate = self
        
        /*
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
         */
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        logoImageView.bounds = CGRect(x: 0, y: 0, width: 150, height: 150)
        logoImageView.center = CGPoint(x: view.bounds.size.width/2.0, y: logoImageView.bounds.size.height/2.0 + view.bounds.size.height/4)
        shadowView.frame = logoImageView.frame
        
        nameTextField.bounds = CGRect(x: 0, y: 0, width: view.bounds.size.width - 40, height: 44)
        nameTextField.center = CGPoint(x: view.bounds.size.width/2.0, y: logoImageView.center.y + logoImageView.bounds.size.height/2.0 + 20 + 22)
    }
}

