//
//  ChatViewController.swift
//  DrdshChatSDK
//
//  Created by Gaurav Gudaliya R on 16/03/20.
//

import UIKit
import MobileCoreServices
import IQKeyboardManagerSwift

let imageCache = NSCache<NSString, UIImage>()
class ChatViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {

    @IBOutlet weak var btnSend: GGButton!
    @IBOutlet weak var btnLike: GGButton!
    @IBOutlet weak var btnDisLike: GGButton!
    @IBOutlet weak var btnMail: GGButton!
    @IBOutlet weak var btnAttachment: GGButton!
    @IBOutlet weak var btnWebSite: GGButton!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var agentView: UIView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var typingView: UIView!
    @IBOutlet weak var lblTyping: UILabel!
    @IBOutlet weak var lblCopyRight: UILabel!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var txtMessage: UITextField!
    
    var timer:Timer = Timer()
    var list:[MessageModel] = []
    var agentName = "Agent"
    var CloseBarItem : UIBarButtonItem?
    var userdata : [String:AnyObject] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            self.txtMessage.keyboardDistanceFromTextField = -((window?.safeAreaInsets.bottom ?? 00)-10)
        }
        table.transform = CGAffineTransform(scaleX: 1, y: -1)
        self.view.backgroundColor = DrdshChatSDKTest.shared.config.bgColor.Color()
        self.btnAttachment.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showAttachmentButton
        self.btnMail.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showSendTranscriptButton
        self.btnLike.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showFeedbackButton
        self.btnDisLike.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showFeedbackButton
        self.imgView.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showAgentPhoto
       
        self.agentView.backgroundColor = DrdshChatSDKTest.shared.config.secondryColor
        self.txtMessage.placeholder = DrdshChatSDKTest.shared.config.typeHere.Local()
        btnWebSite.setTitle(DrdshChatSDKTest.shared.localizedString(stringKey: "Powered by Drdsh"), for: .normal)
        if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus == 1{
            self.title = DrdshChatSDKTest.shared.config.waitingForAgent.Local()
            timer = Timer(timeInterval: TimeInterval(DrdshChatSDKTest.shared.AllDetails.embeddedChat.maxWaitTime), target: self, selector: #selector(invitationMaxWaitTimeExceeded), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        }
        
        CommonSocket.shared.CommanEmitSokect(command: .joinVisitorsRoom,data: [[
            "dc_vid":DrdshChatSDKTest.shared.AllDetails.visitorID]]){ data in
            self.userdata = data
            if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus == 2{
                CommonSocket.shared.CommanEmitSokect(command: .visitorJoinAgentRoom,data:[self.userdata]){ data in
                    
                }
            }
        }
        if DrdshChatSDKTest.shared.config.local == "ar"{
            self.lblName.textAlignment = .right
            self.lblTyping.textAlignment = .right
            self.txtMessage.textAlignment = .right
        }
        self.agentView.isHidden = true
        self.typingView.isHidden = true
        
        self.table.tableFooterView = UIView()
        btnSend.setImage(DrdshChatSDKTest.shared.config.sendMessageImage, for: .normal)
        btnLike.setImage(DrdshChatSDKTest.shared.config.likeImage, for: .normal)
        btnDisLike.setImage(DrdshChatSDKTest.shared.config.disLikeImage, for: .normal)
        btnLike.setImage(DrdshChatSDKTest.shared.config.likeSelctedImage, for: .selected)
        btnDisLike.setImage(DrdshChatSDKTest.shared.config.disLikeSelctedImage, for: .selected)
        
        btnMail.setImage(DrdshChatSDKTest.shared.config.mailImage, for: .normal)
        btnAttachment.setImage(DrdshChatSDKTest.shared.config.attachmentImage, for: .normal)
        imgView.image = DrdshChatSDKTest.shared.config.userPlaceHolderImage
        
        var backImage = DrdshChatSDKTest.shared.config.backImage
        if DrdshChatSDKTest.shared.config.local == "ar"{
            backImage = backImage.rotate(radians: .pi)
        }
        
        let barItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backAction))
        navigationItem.leftBarButtonItem = barItem
        self.CloseBarItem = UIBarButtonItem(title: DrdshChatSDKTest.shared.config.chatClose.Local(), style: .plain, target: self, action: #selector(dissmissView))
        navigationItem.rightBarButtonItem = self.CloseBarItem
        self.navigationItem.rightBarButtonItem = nil
        
        if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus != 2{
    
        }else if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus == 2{
            if DrdshChatSDKTest.shared.AgentDetail.agent_id == ""{
                self.title = DrdshChatSDKTest.shared.config.connecting.Local()
            }else{self.setAgentDetail()}
            self.navigationItem.rightBarButtonItem = self.CloseBarItem
            
        }
        CommonSocket.shared.visitorLoadChatHistory(data: [[
            "appSid" : DrdshChatSDKTest.shared.config.appSid,
            "mid":DrdshChatSDKTest.shared.AllDetails.messageID]]) { (data) in
            if data.count > 0{
                if let arrDic = data[0] as? [[String:AnyObject]]{
                    self.list <= arrDic
                    self.list = self.list.reversed()
                    self.table.reloadData()
                    self.table.scroll(to: .top, animated: false)
                }
            }
            debugPrint(data)
        }
        CommonSocket.shared.agentDetail = { t in
            self.setAgentDetail()
            self.table.reloadData()
        }
        btnWebSite.action = {
            UIApplication.shared.open(URL(string: "https://www.drdsh.live")!, options: [:]) { (status) in
                
            }
        }
        btnSend.action = {
            if self.txtMessage.text! == ""{return}
            let text = self.txtMessage.text!
            self.txtMessage.text! = ""
            CommonSocket.shared.CommanEmitSokect(command: .sendVisitorMessage,data: [[
               "dc_id":DrdshChatSDKTest.shared.AllDetails.companyId,
               "dc_mid":DrdshChatSDKTest.shared.AllDetails.messageID,
               "dc_vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
               "dc_agent_id":DrdshChatSDKTest.shared.AllDetails.agentId,
               "message":text,
               "is_attachment":0,
               "attachment_file":"",
               "file_type":"",
               "file_size":"",
               "send_by": 2,
               "dc_name":DrdshChatSDKTest.shared.AllDetails.name]]){ data in
                var m:MessageModel = MessageModel()
                m <= data
                                       self.list.insert(m, at: 0)
                                       self.table.reloadData()
                                       self.table.scroll(to: .top, animated: true)
                                    
            }
        }
        btnLike.action = {
            CommonSocket.shared.CommanEmitSokect(command: .updateVisitorRating,data: [[
                "mid":DrdshChatSDKTest.shared.AllDetails.messageID,
                "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
                "feedback":"good"]]){data in}
            self.btnLike.isSelected = true
            self.btnDisLike.isSelected = false
        }
        btnDisLike.action = {
            CommonSocket.shared.CommanEmitSokect(command: .updateVisitorRating,data: [[
                "mid":DrdshChatSDKTest.shared.AllDetails.messageID,
                "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
                "feedback":"bad"]]){data in}
            self.btnLike.isSelected = false
            self.btnDisLike.isSelected = true
        }
        btnMail.action = {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "RateViewController") as! RateViewController
           vc.modalPresentationStyle = .overFullScreen
           vc.type = 2
           vc.successHandler = {
               
           }
           self.present(vc, animated: true) {
               
           }
        }
        btnAttachment.action = {
           AGImagePickerController(with: self, allowsEditing: true, media: .both, iPadSetup: self.btnAttachment)
        }
        CommonSocket.shared.ipBlocked { data in
            if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus == 2{
                DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus = 0
            }
            self.timer.invalidate()
            self.agentView.isHidden = true
            self.messageView.isHidden = true
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewController") as! OfflineViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
        CommonSocket.shared.totalOnlineAgents { data in
            debugPrint(data)
        }
        CommonSocket.shared.agentAcceptedChatRequest { data in
            DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus = 2
            DrdshChatSDKTest.shared.AgentDetail <= data
            DrdshChatSDKTest.shared.AllDetails.agentId = data["agent_id"] as! String
            DrdshChatSDKTest.shared.AgentDetail.agent_name = data["name"] as! String
            DrdshChatSDKTest.shared.AgentDetail.visitor_message_id = data["mid"] as! String
            self.setAgentDetail()
            self.navigationItem.rightBarButtonItem = self.CloseBarItem
        }
        CommonSocket.shared.agentSendNewMessage { data in
            var m:MessageModel = MessageModel()
            m <= data
            if self.list.first(where: { (model) -> Bool in
                model._id == m._id
            }) == nil{
                self.list.insert(m, at: 0)
                self.table.reloadData()
                self.table.scroll(to: .top, animated: true)
            }
        }
        CommonSocket.shared.agentChatSessionTerminated { data in
            if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus == 2{
                DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus = 0
            }
            self.timer.invalidate()
            self.agentView.isHidden = true
            self.messageView.isHidden = true
        }
        CommonSocket.shared.agentTypingListener { data in
            if (data["ts"] as! Int) == 2{
                self.typingView.isHidden = true
            }else{
                 self.lblTyping.text = data["message"] as? String ?? ""
                self.typingView.isHidden = false
            }
            self.lblTyping.text = data["message"] as? String ?? ""
        }
        CommonSocket.shared.newAgentAcceptedChatRequest { data in
            DrdshChatSDKTest.shared.AllDetails.agentId = data["agent_id"] as! String
            DrdshChatSDKTest.shared.AgentDetail <= data
            DrdshChatSDKTest.shared.AgentDetail.agent_name = data["name"] as! String
            DrdshChatSDKTest.shared.AgentDetail.visitor_message_id = data["mid"] as! String
            self.timer.invalidate()
            self.setAgentDetail()
        }
    }
    func setAgentDetail(){
        if DrdshChatSDKTest.shared.AgentDetail.agent_id != ""{
            self.title = ""
            self.timer.invalidate()
            
            let strProdile = DrdshChatSDKTest.shared.AgentDetail.agent_image
            imgView.setImage(urlString: strProdile)
            if DrdshChatSDKTest.shared.AllDetails.embeddedChat.showAgentPanel{
                 self.agentView.isHidden = false
            }
            self.lblName.text = DrdshChatSDKTest.shared.AgentDetail.agent_name
        }
    }
    @objc func invitationMaxWaitTimeExceeded(){
        timer.invalidate()
        CommonSocket.shared.CommanEmitSokect(command: .invitationMaxWaitTimeExceeded,data: [[
            "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
            "form":DrdshChatSDKTest.shared.AllDetails.embeddedChat.displayForm]]) { (data) in
            debugPrint(data)
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewController") as! OfflineViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    @objc func backAction(){
        if DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus == 2{
            CommonSocket.shared.disConnect()
            self.dismiss(animated: true, completion: nil)
        }else{
            self.timer.invalidate()
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewController") as! OfflineViewController
             self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    @objc func dissmissView(){
        self.timer.invalidate()
        if DrdshChatSDKTest.shared.AllDetails.embeddedChat.showExitSurvey{
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "RateViewController") as! RateViewController
            vc.modalPresentationStyle = .overFullScreen
            vc.successHandler = {
                DrdshChatSDKTest.shared.AllDetails.visitorConnectedStatus = 0
                self.agentView.isHidden = true
                self.messageView.isHidden = true
                self.navigationItem.rightBarButtonItem = nil
            }
            self.present(vc, animated: true) {
                
            }
        }else{
            CommonSocket.shared.CommanEmitSokect(command: .visitorEndChatSession,data: [[
                "id":DrdshChatSDKTest.shared.AllDetails.companyId,
                "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
                "name":DrdshChatSDKTest.shared.AllDetails.name]]) { (data) in
                self.agentView.isHidden = true
                self.messageView.isHidden = true
                self.navigationItem.rightBarButtonItem = nil
            }
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.list[indexPath.row].isSystem == 1 || self.list[indexPath.row].isWelcome == 1 || self.list[indexPath.row].isDeleted == 1 || self.list[indexPath.row].isTransfer == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "systemTableViewCell", for: indexPath) as! systemTableViewCell
            cell.lblMessage.text = self.list[indexPath.row].message
            cell.lblMessage.textAlignment = .left
            if DrdshChatSDKTest.shared.config.local == "ar"{
                cell.lblMessage.textAlignment = .right
            }
            return cell
        }
        if self.list[indexPath.row].send_by == 2{
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyTableViewCell", for: indexPath) as! MyTableViewCell
            let strProdile = DrdshChatSDKTest.shared.AttachmentbaseURL+self.list[indexPath.row].agent_image
            cell.imgProfile.setImage(urlString: strProdile)
            cell.lblName.text = GGUserSessionDetail.shared.name
            cell.lblMessage.text = self.list[indexPath.row].message
            cell.lblTime.text = self.list[indexPath.row].updatedAt.toUTCDate(format: .shipmentSendDate)?.timePassed()
            cell.imgAttachment.image = nil
            cell.imgAttachment.isHidden = self.list[indexPath.row].is_attachment == 0
            cell.lblMessage.isHidden = self.list[indexPath.row].is_attachment == 1
            if self.list[indexPath.row].is_attachment == 1{
                let strUrl = DrdshChatSDKTest.shared.AttachmentbaseURL+self.list[indexPath.row].attachment_file
                cell.imgAttachment.setImage(urlString: strUrl)
                if self.list[indexPath.row].attachment_file == ""{
                    cell.imgAttachment.setImage(urlString: self.list[indexPath.row].localUrl)
                }else{
                    let strUrl = DrdshChatSDKTest.shared.AttachmentbaseURL+self.list[indexPath.row].attachment_file
                    cell.imgAttachment.setImage(urlString: strUrl)
                }
            }
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "AgentTableViewCell", for: indexPath) as! AgentTableViewCell
            let strProdile = DrdshChatSDKTest.shared.AttachmentbaseURL+self.list[indexPath.row].agent_image
            cell.imgProfile.setImage(urlString: strProdile)
            cell.lblName.text = self.list[indexPath.row].agent_name
            cell.lblMessage.text = self.list[indexPath.row].message
             cell.lblTime.text = self.list[indexPath.row].updatedAt.toUTCDate(format: .shipmentSendDate)?.timePassed()
            cell.imgAttachment.image = nil
            cell.imgAttachment.isHidden = self.list[indexPath.row].is_attachment == 0
            cell.lblMessage.isHidden = self.list[indexPath.row].is_attachment == 1
            if self.list[indexPath.row].is_attachment == 1{
                if self.list[indexPath.row].attachment_file == ""{
                    cell.imgAttachment.setImage(urlString: self.list[indexPath.row].localUrl)
                }else{
                    let strUrl = DrdshChatSDKTest.shared.AttachmentbaseURL+self.list[indexPath.row].attachment_file
                    cell.imgAttachment.setImage(urlString: strUrl)
                }
            }
            return cell
        }
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        CommonSocket.shared.CommanEmitSokect(command: .visitorTyping,data: [[
            "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
              "id":DrdshChatSDKTest.shared.AllDetails.companyId,
              "agent_id":DrdshChatSDKTest.shared.AllDetails.agentId,
              "ts":1,
              "message":GGUserSessionDetail.shared.name+DrdshChatSDKTest.shared.config.startTyping.Local(),
              "stop":false]]){data in}
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        CommonSocket.shared.CommanEmitSokect(command: .visitorTyping,data: [[
            "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
              "id":DrdshChatSDKTest.shared.AllDetails.companyId,
              "agent_id":DrdshChatSDKTest.shared.AllDetails.agentId,
              "ts":2,
              "message":GGUserSessionDetail.shared.name+DrdshChatSDKTest.shared.config.isTyping.Local(),
              "stop":true]]){data in}
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        CommonSocket.shared.CommanEmitSokect(command: .visitorTyping,data: [[
            "vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
              "id":DrdshChatSDKTest.shared.AllDetails.companyId,
              "agent_id":DrdshChatSDKTest.shared.AllDetails.agentId,
              "ts":1,
              "message":GGUserSessionDetail.shared.name+DrdshChatSDKTest.shared.config.isTyping.Local(),
              "stop":false]]){data in}
        return true
    }
}
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
         picker.dismiss(animated: true) {
            if let image = (info[UIImagePickerControllerEditedImage] as? UIImage){
                 let imageName = "\(NSDate().timeIntervalSince1970 * 1000)"
                let imagePath = self.getDocumentsDirectory().appendingPathComponent(imageName)
                
                if let jpegData = UIImageJPEGRepresentation(image, 0.5) {
                       try? jpegData.write(to: imagePath)
                   }
                if #available(iOS 11.0, *) {
                    let url = imagePath
                    let v = VisitorIdModel()
                    v._id = DrdshChatSDKTest.shared.AllDetails.visitorID
                    v.name = DrdshChatSDKTest.shared.AllDetails.name
                    v.image = ""
                    let m = MessageModel()
                    m.company_id = DrdshChatSDKTest.shared.AllDetails.companyId
                    m.is_attachment = 1
                    m.localUrl = url.absoluteString
                    m.send_by = 2
                    m.updatedAt = Date().toString(format: .shipmentSendDate)
                    m.visitor_id = v
                    m.visitor_message_id = DrdshChatSDKTest.shared.AllDetails.messageID
                    m.localId = url.lastPathComponent
                    self.list.insert(m, at: 0)
                    DispatchQueue.main.async {
                        self.table.reloadData()
                        self.table.scroll(to: .top, animated: true)
                    }
                    if let base64String = try? Data(contentsOf: url).base64EncodedString() {
                        CommonSocket.shared.CommanEmitSokect(command: .sendVisitorMessage,data: [[
                           "dc_id":DrdshChatSDKTest.shared.AllDetails.companyId,
                            "dc_mid":DrdshChatSDKTest.shared.AllDetails.messageID,
                            "dc_vid":DrdshChatSDKTest.shared.AllDetails.visitorID,
                            "dc_agent_id":DrdshChatSDKTest.shared.AllDetails.agentId,
                            "send_by": 2,
                            "message":url.lastPathComponent,
                            "is_attachment":1,
                            "attachment_file":base64String,
                            "file_type":url.pathExtension,
                            "file_size":url.fileSize,
                            "dc_name":DrdshChatSDKTest.shared.AllDetails.name,
                            "localId":url.lastPathComponent]]){ data in
                            var mm:MessageModel = MessageModel()
                            mm <= data
                            if let indexaPath = self.list.firstIndex(where: { (model) -> Bool in
                                model.localId == m.localId
                            }){
                                self.list.remove(at: indexaPath)
                                self.list.insert(mm, at: indexaPath)
                            }
                            self.table.reloadData()
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { }
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

class MyTableViewCell:UITableViewCell{
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var imgAttachment: GGImageViewPopup!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var backView: UIView!
    override func awakeFromNib() {
        self.transform = CGAffineTransform(scaleX: 1, y: -1)
        self.imgAttachment.isHidden = true
        self.imgAttachment.image = nil
        self.lblTime.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showTimestampsChatWindow
        imgProfile.image = DrdshChatSDKTest.shared.config.userPlaceHolderImage
        self.backView.layer.cornerRadius = 10
        self.backView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            self.backView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner,.layerMaxXMaxYCorner]
            if DrdshChatSDKTest.shared.config.local == "ar"{
                self.backView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner,.layerMaxXMaxYCorner]
                self.lblName.textAlignment = .left
                self.lblMessage.textAlignment = .left
                self.lblTime.textAlignment = .left
            }
        } else {
            
        }
       self.backView.backgroundColor = DrdshChatSDKTest.shared.config.myChatBubbleColor.Color()
       self.lblMessage.textColor = DrdshChatSDKTest.shared.config.myChatTextColor.Color()
       self.lblTime.textColor = DrdshChatSDKTest.shared.config.myChatTextColor.Color()
    }
}
class AgentTableViewCell:UITableViewCell{
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var imgAttachment: GGImageViewPopup!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var backView: UIView!
    override func awakeFromNib() {
        self.transform = CGAffineTransform(scaleX: 1, y: -1)
        imgAttachment.isHidden = true
        self.imgAttachment.image = nil
        imgProfile.image = DrdshChatSDKTest.shared.config.userPlaceHolderImage
        self.backView.layer.cornerRadius = 10
        self.backView.clipsToBounds = true
        self.lblTime.isHidden = !DrdshChatSDKTest.shared.AllDetails.embeddedChat.showTimestampsChatWindow
        if #available(iOS 11.0, *) {
           
            self.backView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner,.layerMaxXMaxYCorner]
            if DrdshChatSDKTest.shared.config.local == "ar"{
               self.backView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner,.layerMaxXMaxYCorner]
                self.lblName.textAlignment = .right
                self.lblMessage.textAlignment = .right
                self.lblTime.textAlignment = .right
            }
        } else {
            
        }
        self.backView.backgroundColor = DrdshChatSDKTest.shared.config.oppositeChatBubbleColor.Color()
        self.lblMessage.textColor = DrdshChatSDKTest.shared.config.oppositeChatTextColor.Color()
        self.lblTime.textColor = DrdshChatSDKTest.shared.config.oppositeChatTextColor.Color()
    }
}
class systemTableViewCell:UITableViewCell{
    override func awakeFromNib() {
           self.transform = CGAffineTransform(scaleX:  1, y: -1)
       }
    @IBOutlet weak var lblMessage: UILabel!
}
public enum DateFormatterType: String {
    case shipmentSendDate = "yyyy-MM-ddTHH:mm:ss.sssZ"
    case shipmentDisplayDate = "dd-MM-yyyy hh:mm a"
    case orderDisplayDate = "MMM dd, yyyy hh:mm a"
}
//2020-03-21T10:03:54.679Z
extension Date {
   
    // Initializes Date from string and format
    public init?(fromUTCString string: String, format: DateFormatterType) {
        self.init(fromUTCString: string, format: format.rawValue)
    }
    
    public init?(fromUTCString string: String, format: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = format
         formatter.locale = Locale(identifier: "ar_DZ")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: string) {
            self = date
        } else {
            return nil
        }
    }
    
    // Converts Date to String, with format
    public func toString(format: DateFormatterType, identifier: TimeZone = TimeZone.current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = identifier
        formatter.dateFormat = format.rawValue
        return formatter.string(from: self)
    }
    
    func toLocalTimeZone(format: DateFormatterType)  -> String {
        return self.toString(format: format, identifier: TimeZone.current)
    }
}
extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }

    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}
extension String {
    
    func toUTCDate(format: DateFormatterType) -> Date? {
        return Date(fromUTCString: self, format: format)
    }
}


extension Date {
    
    public func timePassed() -> String {
        let date = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: self, to: date, options: [])
        
        var str: String
        
        if components.year! >= 1 {
            components.year == 1 ? (str = DrdshChatSDKTest.shared.localizedString(stringKey: "year")) : (str = DrdshChatSDKTest.shared.localizedString(stringKey:"years"))
            return String(format: components.year!.description+" "+str, components.year!.description)
        } else if components.month! >= 1 {
            components.month == 1 ? (str = DrdshChatSDKTest.shared.localizedString(stringKey:"month")) : (str = DrdshChatSDKTest.shared.localizedString(stringKey:"months"))
            return String(format: components.month!.description+" "+str, components.month!.description)
        } else if components.day! >= 1 {
            components.day == 1 ? (str = DrdshChatSDKTest.shared.localizedString(stringKey:"day")) : (str = DrdshChatSDKTest.shared.localizedString(stringKey:"days"))
            return String(format: components.day!.description+" "+str, components.day!.description)
        } else if components.hour! >= 1 {
            components.hour == 1 ? (str = DrdshChatSDKTest.shared.localizedString(stringKey:"hour")) : (str = DrdshChatSDKTest.shared.localizedString(stringKey:"hours"))
            return String(format: components.hour!.description+" "+str, components.hour!.description)
        } else if components.minute! >= 1 {
            components.minute == 1 ? (str = DrdshChatSDKTest.shared.localizedString(stringKey:"minute")) : (str = DrdshChatSDKTest.shared.localizedString(stringKey:"minutes"))
            return String(format: components.minute!.description+" "+str, components.minute!.description)
        } else if components.second! >= 1 {
            components.second == 1 ? (str = DrdshChatSDKTest.shared.localizedString(stringKey:"second")) : (str = DrdshChatSDKTest.shared.localizedString(stringKey:"seconds"))
            return String(format: components.second!.description+" "+str, components.second!.description)
        } else {
            return DrdshChatSDKTest.shared.localizedString(stringKey:"JustNow")
        }
    }
    func toAge() -> Int {
        let now = Date()
        let ageComponents = Calendar.current.dateComponents([.year], from: self, to: now)
        return ageComponents.year ?? 0
    }
}

extension UITableView {
    func scroll(to: ScrollsTo, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            let numberOfSections = self.numberOfSections
            let numberOfRows = self.numberOfRows(inSection: numberOfSections-1)
            
            guard numberOfRows > 0 else { return }
            switch to{
            case .top:
                let indexPath = IndexPath(row: 0, section: 0)
                self.scrollToRow(at: indexPath, at: .top, animated: animated)
                break
                
            case .bottom:
                let indexPath = IndexPath(row: numberOfRows-1, section: (numberOfSections-1))
                self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
                break
            }
        }
    }
    
    enum ScrollsTo {
        case top,bottom
    }
}
extension UIImageView{
    func setImage(urlString:String){
        self.image = DrdshChatSDKTest.shared.config.userPlaceHolderImage
        if urlString == "" || urlString == DrdshChatSDKTest.shared.AttachmentbaseURL{return}
        if let cachedImage = imageCache.object(forKey: NSString(string: urlString)) {
              self.image =  cachedImage
        }else{
            DispatchQueue.global(qos: .background).async {
                if let url = URL(string:urlString){
                    if let data = try? Data(contentsOf: url){
                        if let image1: UIImage = UIImage(data: data){
                            DispatchQueue.main.async {
                                imageCache.setObject(image1, forKey:urlString as NSString)
                                 self.image = image1
                            }
                        }
                    }
                }
            }
        }
    }
}
class GGImageViewPopup: UIImageView {
    var tempRect: CGRect?
    var bgView: UIView!
    
    var animated: Bool = true
    var intDuration = 0.25
    //MARK: Life cycle
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(popUpImageToFullScreen))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
        //        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Actions of Gestures
    @objc func exitFullScreen () {
        let imageV = bgView.subviews[0] as! UIImageView
        
        UIView.animate(withDuration: intDuration, animations: {
                imageV.frame = self.tempRect!
                self.bgView.alpha = 0
            }, completion: { (bol) in
                self.bgView.removeFromSuperview()
        })
    }
    
    @objc func popUpImageToFullScreen() {
        
        if let window = UIApplication.shared.delegate?.window {
            let parentView = self.findParentViewController(self)!.view
            
            bgView = UIView(frame: UIScreen.main.bounds)
            bgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(exitFullScreen)))
            bgView.alpha = 0
            bgView.backgroundColor = UIColor.black
            let imageV = UIImageView(image: self.image)
            let point = self.convert(self.bounds, to: parentView)
            imageV.frame = point
            tempRect = point
            imageV.contentMode = .scaleAspectFit
            self.bgView.addSubview(imageV)
            window?.addSubview(bgView)
            
            if animated {
                UIView.animate(withDuration: intDuration, animations: {
                    self.bgView.alpha = 1
                    imageV.frame = CGRect(x: 0, y: 0, width: (parentView?.frame.width)!, height: (parentView?.frame.width)!)
                    imageV.center = (parentView?.center)!
                })
            }
        }
    }
    
    func findParentViewController(_ view: UIView) -> UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
