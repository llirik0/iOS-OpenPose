//
//  LightStatusImagePickerController.swift
//  iOSOpenPose
//
//  Created by Eugene Bokhan on 12/31/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit

class LightStatusImagePickerController: UIImagePickerController {
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return UIStatusBarStyle.lightContent
    }
}
