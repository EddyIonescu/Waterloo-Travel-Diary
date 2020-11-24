//
//  TripUploader.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-10-27.
//  Copyright © 2020 Eddy. All rights reserved.
//

import Foundation
import AWSCognito
import AWSS3
import Keys
import UIKit

let S3BUCKETNAME = "wpti-app-travel-data"

class TripUploader {
    init() {
        // Initialize the Amazon Cognito credentials provider.
        // As the lifetime of a TripUploader is at most a few minutes (a new TripUploader
        // is made on each use) the credentials are valid for 5 minutes.
        let keys = WaterlooTravelDiaryKeys()
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: .CACentral1,
            identityPoolId: keys.cognitoIdentityPoolID
        );
        let configuration = AWSServiceConfiguration(
            region: .CACentral1,
            credentialsProvider: credentialsProvider
        );
        AWSServiceManager.default().defaultServiceConfiguration = configuration;
    }
    
    func getUserID() -> String? {
        let userDefaults = UserDefaults.standard
        return userDefaults.string(forKey: "email")
        // If anonymous mode:
        // return UIDevice.current.identifierForVendor?.uuidString
    }

    func uploadTrips() -> Bool {
        let userID = getUserID()
        if (userID == nil) {
            return false
        }
        // Gets list of all trip files and uploads ones that have not yet been uploaded.
        let tripFilePaths = getTripFiles()
        // Get already uploaded files from S3 as to upload only ones not there.
        let request = AWSS3ListObjectsV2Request()!
        request.bucket = S3BUCKETNAME
        request.prefix = userID
        AWSS3.default().listObjectsV2(request).continueWith { (task) -> Void in
            var alreadyUploaded: Set<String> = []
            let s3TaskContents = task.result?.contents
            if (s3TaskContents != nil) { // May be nil if nothing with the prefix exists in S3 (ie. new device).
                for s3Obj in s3TaskContents! {
                    alreadyUploaded.insert(String(s3Obj.key!.split(separator: "/").last!))
                }
            }
            // Upload the files.
            for tripFilePath in tripFilePaths {
                if !alreadyUploaded.contains(tripFilePath) {
                    self.uploadTrip(filename: tripFilePath, userID: userID!)
                }
            }
        }
        return true
    }

    func uploadTrip(filename: String, userID: String) {
        let filepathURL = Storage.getURL(for: .documents).appendingPathComponent(filename, isDirectory: false)
        if let data = FileManager.default.contents(atPath: filepathURL.path) {
            uploadFile(data: data, filename: filename, userID: userID)
        }
    }

    func uploadFile(data: Data, filename: String, userID: String) {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { (task, progress) in
            DispatchQueue.main.async(execute: {
                // Update a progress bar
            })
        }

       var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                // Do something e.g. Alert a user for transfer completion.
                // On failed uploads, `error` contains the error object.
            })
        }

        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadData(
            data,
            bucket: S3BUCKETNAME,
            key: userID + "/" + filename,
            contentType: "application/json",
            expression: expression,
            completionHandler: completionHandler
        ).continueWith { (task) -> Any? in
            if let error = task.error {
                print("Error : \(error.localizedDescription)")
            }
            if task.result != nil {
                let url = AWSS3.default().configuration.endpoint.url
                let publicURL = url?.appendingPathComponent(S3BUCKETNAME).appendingPathComponent(filename)
                if let absoluteString = publicURL?.absoluteString {
                    print("Uploaded Trip URL: ", absoluteString)
                }
            }
            return nil
        }
    }
}
