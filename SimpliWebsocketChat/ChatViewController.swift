//
//  ChatViewController.swift
//  SimpliWebsocketChat
//
//  Created by Murat Zhakupov on 04.02.2018.
//  Copyright © 2018 Murat Zhakupov. All rights reserved.
//

import UIKit
import MessageKit
import SocketIO

class ChatViewController: MessagesViewController {
    
    let stringUrl = "http://localhost:8282"
    lazy var manager = SocketManager(socketURL: URL(string: stringUrl)!, config: [.log(true), .compress])
    var socket: SocketIOClient?
    
    var messageList: [MockMessage] = []
    
    var userName = ""
    
    var imageForSend: UIImage? {
        didSet {
            if imageForSend != nil {
                sendImage()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = self.userName
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        messageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "attach"),
                            style: .plain,
                            target: self,
                            action: #selector(ChatViewController.handleKeyboardButton))
        ]


        //Configure Socket and recieve messages from server
        socket = manager.defaultSocket
        socket?.on(clientEvent: .connect) {data, ack in
            print("Socket COnnected")
            var json = [String: Any]()
            json["username"] = self.userName
            json["userAvatar"] = "avatar.png"
            //Enter in ChatRoom on Server
            self.socket?.emitWithAck("new user", json).timingOut(after: 1, callback: {data in
                print(data)
            })
        }
        
        socket?.on("currentAmount") {data, ack in
            guard let cur = data[0] as? Double else { return }
            
            self.socket?.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
                self.socket?.emit("update", ["amount": cur + 2.50])
            }
            ack.with("Got your currentAmount", "dude")
        }
        
        socket?.connect()
        //New messages Handle
        socket?.on("new message") { [weak self] data, ack in
            print("Recieved new message: \(data.count)")
            guard let newMessage = data[0] as? [String: Any] else { return }
            let senderName = newMessage["username"] as! String
            if senderName != self?.userName {
                    DispatchQueue.main.async {
                        let text = newMessage["msg"] as! String
                        let message = self?.createMessage(text: text, senderName: senderName, date: Date())
                        self?.messageList.append(message!)
                        self?.messagesCollectionView.reloadData()
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
        }
        //
        //New messages Image Handle
        socket?.on("new message image") { [weak self] data, ack in
            print("Recieved new message: \(data.count)")
            guard let newMessage = data[0] as? [String: Any] else { return }
            let senderName = newMessage["username"] as! String
            if senderName != self?.userName {
                let imageFileName = newMessage["serverfilename"] as! String
                DispatchQueue.global().async {
                    var sUrl = self!.stringUrl
                    sUrl += "/\(imageFileName)"
                    let url = NSURL(string: sUrl)
                    print(sUrl)
                    let imageData = try! NSData(contentsOf: url! as URL)
                    if imageData != nil {
                        if let messageImage = UIImage(data: imageData! as Data) {
                            DispatchQueue.main.async {
                                self?.createImageMessage(image: messageImage, senderName: senderName)
                            }
                        }
                    }
                }
            }
        }
        //
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleKeyboardButton() {
        messageInputBar.inputTextView.resignFirstResponder()
        optionsMenu()
    }
    
    func createMessage(text: String, senderName: String, date: Date) -> MockMessage {
        let uniqueID = NSUUID().uuidString
        let sender = Sender(id: senderName, displayName: senderName)
        let message = MockMessage(text: text, sender: sender, messageId: uniqueID, date: date)
        return message
    }
    
    func createImageMessage(image: UIImage, senderName: String) {
        let sender = Sender(id: senderName, displayName: senderName)
        let imageMessage = MockMessage(image: image, sender: sender, messageId: UUID().uuidString, date: Date())
        self.messageList.append(imageMessage)
        self.messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
    
    func sendImage() {
        if self.imageForSend != nil {
            print("SENDING IMAGE TO SERVER")
            var json = [String: Any]()
            json["username"] = self.userName
            json["userAvatar"] = "avatar.png"
            json["hasMsg"] = false
            json["hasFile"] = true
            json["istype"] = "image"
            json["isImageFile"] = true
            json["showme"] = true
            self.socket?.emitWithAck("send-message", json).timingOut(after: 5, callback: { data in
                
                print(data)
                let data1 = data[0] as! [String: Any]
                if (data1["success"] as! Int) == 1 {
                    print("Message Sended")
                    self.uploadRequest()
                }
            })
         createImageMessage(image: imageForSend!, senderName: self.userName)
        }
    }
    
    func uploadRequest() {
        print("UPLOADING IMAGE!")
        let myUrl = URL(string:"http://localhost:8282/v1/uploadImage")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        let imageData = UIImageJPEGRepresentation(imageForSend!, 0.5)
        var json = [String: Any]()
        json["username"] = self.userName
        json["userAvatar"] = "avatar.png"
        //json["file"] = imageData!
        json["filename"] = "image\(Date())"
        json["hasMsg"] = false
        json["hasFile"] = true
        json["istype"] = "image"
        json["isImageFile"] = true
        json["showme"] = true
        if imageData != nil {
            let boundary = generateBoundaryString()
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = createBodyWithParameters(parameters: json, filePathKey: "file", imageDataKey: imageData!, boundary: boundary) as Data
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print("error=\(error)")
                    return
                }
                print("******* response = \(response)")
                
            }
            task.resume()
        }
    }
    
    func createBodyWithParameters(parameters: [String: Any]?, filePathKey: String?, imageDataKey: Data, boundary: String) -> NSData {
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters! {
                let line1 = "--\(boundary)\r\n"
                body.append(line1.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
                let line2 = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
                body.append(line2.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
                let line3 = "\(value)\r\n"
                body.append(line3.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
            }
        }
        
        let filename = "user-profile.jpg"
        let mimetype = "image/jpg"
        let line4 = "--\(boundary)\r\n"
        body.append(line4.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        let line5 = "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n"
        body.append(line5.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        let line6 = "Content-Type: \(mimetype)\r\n\r\n"
        body.append(line6.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        body.append(imageDataKey)
        let line7 = "\r\n"
        body.append(line7.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        
        let line8 = "--\(boundary)--\r\n"
        body.append(line8.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        return body
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func sendTextMessage(message: String) {
        if message.count > 0 {
            var json = [String: Any]()
            json["username"] = self.userName
            json["userAvatar"] = "avatar.png"
            json["msg"] = message
            json["hasMsg"] = 1
            self.socket?.emitWithAck("send-message", json).timingOut(after: 1, callback: {data in
                print("Message Sended")
                print(data)
            })
        }
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

extension ChatViewController: MessagesDataSource {
    
    func currentSender() -> Sender {
        return Sender(id: self.userName, displayName: self.userName)
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        struct ConversationDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter
            }()
        }
        let formatter = ConversationDateFormatter.formatter
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    func avatar(for message: MessageType, at  indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        let senderName = message.sender.displayName
        let senderInitialsChar = senderName[senderName.startIndex]
        let initials = String(senderInitialsChar)
        let avatar = Avatar(initials: initials)

        return avatar
    }
    
}


// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }
    
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }
    
    // MARK: - Location Messages
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
    
}

extension ChatViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
       
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        
        return [.url, .address, .phoneNumber, .date]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
        //        let configurationClosure = { (view: MessageContainerView) in}
        //        return .custom(configurationClosure)
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
    }
    
}


extension ChatViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped \(cell)")
        if let mediaCell = cell as? MediaMessageCell {
            print("YES PHOTO")
            if let image = mediaCell.imageView.image {
                let OpenImageVC = OpenImageViewController()
                OpenImageVC.imageView.image = nil
                OpenImageVC.imageView.image = image
                navigationController?.pushViewController(OpenImageVC, animated: true)

            }
        }
    }
    
    func didTapTopLabel(in cell: MessageCollectionViewCell) {
        print("Top label tapped")
    }
    
    func didTapBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }
    
}


extension ChatViewController: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: MessageInputBarDelegate {
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        
        // Each NSTextAttachment that contains an image will count as one empty character in the text: String
        if let text = inputBar.inputTextView.text {
                self.sendTextMessage(message: text)
                let attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.blue])
                
                let message = MockMessage(attributedText: attributedText, sender: currentSender(), messageId: UUID().uuidString, date: Date())
                self.messageList.append(message)
                self.messagesCollectionView.reloadData()
            }
        
        inputBar.inputTextView.text = String()
        messagesCollectionView.scrollToBottom()
 
    }
    
}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func optionsMenu() {
        
        let camera = Camera(delegate_: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionMenu.popoverPresentationController?.sourceView = self.view
        
        let takePhoto = UIAlertAction(title: "Снять фото", style: .default) { (alert : UIAlertAction!) in
            camera.presentPhotoCamera(target: self, canEdit: true)
        }
        let sharePhoto = UIAlertAction(title: "Медиатека", style: .default) { (alert : UIAlertAction) in
            camera.presentPhotoLibrary(target: self, canEdit: true)
        }
        
        let cancel = UIAlertAction(title: "Отмена", style: .cancel) { (alert : UIAlertAction) in
            //
        }
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(sharePhoto)
        
        optionMenu.addAction(cancel)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage  {
            imageForSend = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage  {
            imageForSend = image
        } else {
            imageForSend = nil
        }
    }
    
}
