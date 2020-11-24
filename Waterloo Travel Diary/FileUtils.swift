//
//  FileUtils.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-10-29.
//  Copyright © 2020 Eddy. All rights reserved.
//

import Foundation
import os.log

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func getTripFiles(tripLocationsOnly: Bool = false) -> [String] {
    var tripPaths = [String]()
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    do {
        let tripURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        for tripURL in tripURLs {
            if (tripURL.lastPathComponent.contains(".json")) {
                if (!tripLocationsOnly || tripURL.lastPathComponent.contains("tripLocations")) {
                    tripPaths.append(tripURL.lastPathComponent)
                }
            }
        }
    } catch {
        os_log("Error while enumerating files %s",
            log: OSLog.default, type: .error, "\(documentsURL.path): \(error.localizedDescription)")
    }
    tripPaths.sort(by: >)
    return tripPaths
}

func getTrip(tripPath: String) -> [TripRecorder.TripLocation] {
    let storedTrip = Storage.retrieve(
        tripPath,
        from: .documents,
        as: [TripRecorder.TripLocation].self
    )
    return storedTrip
}
