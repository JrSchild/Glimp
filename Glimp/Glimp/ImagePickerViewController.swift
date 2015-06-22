//
//  BABViewControllerSwift.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 10-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class ImagePickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var cropperView: BABCropperView!
    @IBOutlet weak var cropButton: UIButton!
    
    var callback: ((UIImage!) -> ())!
    var croppedImage: UIImage!
    var didUserCancel = false
    var method = UIImagePickerControllerSourceType.Camera

    override func viewDidLoad() {
        super.viewDidLoad()

        self.cropperView.cropSize = CGSizeMake(640.0, 640.0);
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if didUserCancel && self.cropperView.image == nil {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else if self.cropperView.image == nil {
            self.useImagePicker()
        }
    }
    
    func useImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = method
        imagePickerController.allowsEditing = false
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func cropButtonPressed(sender: UIButton) {
        useImagePicker()
    }
    
    @IBAction func chooseCurrentImage(sender: UIButton) {
        cropperView.renderCroppedImage({ (croppedImage) -> Void in
            self.croppedImage = croppedImage
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                if self.callback != nil {
                    self.callback(self.croppedImage)
                }
            })
        })
    }
    
    @IBAction func cancel(sender: UIButton) {
        croppedImage = nil
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            if self.callback != nil {
                self.callback(self.croppedImage)
            }
        })
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        cropperView.image = info[UIImagePickerControllerOriginalImage] as UIImage
        dismissPicker(picker)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        didUserCancel = true
        dismissPicker(picker)
    }
    
    func dismissPicker(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            UIApplication.sharedApplication().statusBarHidden = true
        })
    }
}
