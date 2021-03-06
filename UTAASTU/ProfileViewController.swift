//
//  ProfileViewController.swift
//  UTAASTU
//
//  Created by Abdulmalek S. A. Shefat on 01/08/2017.
//  Copyright © 2017 MSL Dev. All rights reserved.
//

import UIKit
import Firebase
import KRProgressHUD

class ProfileViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,
UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var nameEdit: UITextField!
    @IBOutlet weak var emailEdit: UITextField!
    @IBOutlet weak var phoneEdit: UITextField!
    @IBOutlet weak var birthDateEdit: UITextField!
    @IBOutlet weak var departmentEdit: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var topView: UIView!
    
    var userData: ProfileData?
    var progressHUD: ProgressHUD!
    let departmentPicker = UIPickerView()
    
    var departments : [String] = []
    var currentRow: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(gesture:)))
        view.addGestureRecognizer(tapGesture)
        
        progressHUD = ProgressHUD(text: "uploading... please wait")
        self.view.addSubview(progressHUD)
        
        // Do any additional setup after loading the view.
        
        CustomizeView.dropShadow(layer: topView.layer)
        CustomizeView.dropShadow(layer: bottomView.layer)
        
        loadProfileData()
        initPickerView()
        
    }
    
    //  MAERK: Views
    
    func initImage(image: UIImage){
        
        let newImage = image.scaleImagetoSize(newSize: profileImage.frame.size)
        self.profileImage.image = newImage.circleMask
        CustomizeView.setBorder(layer: profileImage.layer, radius: self.profileImage.bounds.width/2.0)
        
        CustomizeView.dropShadow(layer: profileImage.layer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageClicked(gesture:)))
        
        self.profileImage.addGestureRecognizer(tapRecognizer)
        
    }
    
    //  MARK: Profile Data
    
    func loadProfileData(){
        
        progressHUD.text = "loading... please wait"
        progressHUD.show()
        
        database.child(KUSERS).child((Auth.auth().currentUser?.uid)!).observe(.value, with: {
            (snapshot) in
            
            if snapshot.exists() {
                
                let dic = snapshot.value as! NSDictionary
                
                self.userData = ProfileData.init(dictionary: dic)
                
                self.initProfile(item: self.userData!)
                
            } else {
                
                self.userData = ProfileData.init()
                
                self.initProfile(item: self.userData!)
                
            }
            
            
        })
        
        database.child(KDEPARTMENTS).observe(.value, with: {
            
            (snapshot) in
            
            if snapshot.exists() {
                
                let departmentsValue = (snapshot.value as! String)
                self.departments = departmentsValue.components(separatedBy: ", ")
                
                self.departmentEdit.text = self.departments[(self.userData?.department)!]
            }
            
        })
        
        progressHUD.hide()
    }
    
    func initProfile(item: ProfileData){
        
        nameEdit.text = item.name
        emailEdit.text = item.email
        phoneEdit.text = item.phoneNumber
        birthDateEdit.text = item.birthDate
        
        if item.profilePicture == "" {
            
            initImage(image: UIImage(named: "profile_pic")!)
            
        } else {
            
            imageFromData(imageData: item.profilePicture, withBlock: {
                (image) in
                initImage(image: image!)
                
            })
            
        }
        
    }
    
    //  MARK: Helpers
    
    func isValidInput() -> Bool {
        
        // todo: update user data
        
        if nameEdit.text == "" {
            return false
        }
        if birthDateEdit.text == "" {
            return false
        }
        if phoneEdit.text == "" {
            return false
        }
        
        return true
    }
    
    func uploadProfileDatabase(){
        userData?.updateUserDatabase(completion: {
            (error) in
            
            if error != nil {
                
                KRProgressHUD.showError(withMessage: "error occured, please try again later")
                
            } else {
                
                KRProgressHUD.showSuccess(withMessage: "uploaded successfully")
                
                self.dismiss(animated: true, completion: nil)
                
            }
            
            self.progressHUD.hide()
            
        })
    }
    
    // MARK: StatusBar style change
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    //  MARK: Button Click
    
    @IBAction func backButtonClicked(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonClicked(_ sender: Any) {
        
        if isValidInput() {
            
            progressHUD.text = "uploading... please wait"
            progressHUD.show()
            
            self.userData?.updateUserProfile(completion: {
                (error) in
                
                if error != nil{
                    
                    self.userData?.name = (Auth.auth().currentUser?.displayName)!
                    
                }
                
                self.uploadProfileDatabase()
                
                
            })
            
        } else {
            
            KRProgressHUD.showError(withMessage: "all inputs are required")
            
        }
        
    }
    
    //  MARK: Image Picker
    
    func imageClicked(gesture: UITapGestureRecognizer){
        
        // open image picker
        
        let optionsMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let camera = Camera(delegate_: self)
        
        let takePhoto = UIAlertAction(title: "use camera", style: .default){
            (alert) in
            
            camera.presentCamera(target: self, canEdit: true)
            
        }
        
        let pickPhoto = UIAlertAction(title: "pick picture", style: .default){
            (alert) in
            
            camera.presentPhotoLibrary(target: self, canEdit: true)
            
        }
        
        let cancel = UIAlertAction(title: "cancel", style: .cancel){
            (alert) in
            
        }
        
        optionsMenu.addAction(takePhoto)
        optionsMenu.addAction(pickPhoto)
        optionsMenu.addAction(cancel)
        
        optionsMenu.view.tintColor = UIColor.MaterialColors.Accent.orange500
        self.present(optionsMenu, animated: true, completion: nil)
        optionsMenu.view.tintColor = UIColor.MaterialColors.Accent.orange500
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = (info[UIImagePickerControllerEditedImage] as! UIImage).scaleImagetoSize(newSize: profileImage.frame.size)
        profileImage.image = image.circleMask
        
        let newImage = UIImageJPEGRepresentation((info[UIImagePickerControllerEditedImage] as! UIImage), 0.5)
        userData?.profilePicture = (newImage?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)))!
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: ScrollView & TextFields Fix
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    func didTapView(gesture: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    func addObservers(){
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: nil){
            notification in
            self.keyboardWillShow(notification: notification)
        }
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil){
            notification in
            self.keyboardWillHide(notification: notification)
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(notification: Notification){
        guard let userInfo = notification.userInfo,
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: frame.height, right: 0)
        scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(notification: Notification){
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField{
            
            nextField.becomeFirstResponder()
            
        }else{
            
            textField.resignFirstResponder()
            
        }
        
        return false
    }
    
    //  MARK: PickerView
    
    func initPickerView(){
        departmentPicker.delegate = self
        departmentPicker.dataSource = self
        
        departmentPicker.backgroundColor = UIColor.MaterialColors.Primary.blue200
        
        departmentEdit.inputView = departmentPicker
        
        createToolbar()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return departments.count
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if row == userData?.department {
            pickerView.selectRow(row, inComponent: component, animated: true)
        }
        
        return departments[row]
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        currentRow = row
        departmentEdit.text = departments[row]
        
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: departments[row], attributes: [NSForegroundColorAttributeName: UIColor.MaterialColors.Primary.blue700])
    }
    
    //  MARK: CreatePickerToolbar
    
    func createToolbar(){
        
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.tintColor = UIColor.MaterialColors.Accent.orange500
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(departmentPicked))
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(departmentCancelled))
        
        toolbar.setItems([doneButton, spaceButton, cancelButton], animated: true)
        
        departmentEdit.inputAccessoryView = toolbar
        
    }
    
    func departmentPicked(){
        
        departmentEdit.resignFirstResponder()
        userData?.department = currentRow
        
    }
    
    func departmentCancelled(){
        
        departmentEdit.resignFirstResponder()
        departmentEdit.text = departments[(userData?.department)!]
        
    }
    
    
}
