//
//  ExportConfiguration.swift
//  VIExportSession
//
//  Created by Vito on 06/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class ExportConfiguration {
    var outputURL = URL.temporaryExportURL()
    var fileType: AVFileType = .mp4
    var shouldOptimizeForNetworkUse = false
    var metadata: [AVMetadataItem] = []
}

class VideoConfiguration {
    // Video settings see AVVideoSettings.h
    var videoInputSetting: [String: Any]?
    var videoOutputSetting: [String: Any]?
    var videoComposition: AVVideoComposition?
}

class AudioConfiguration {
    // Audio settings see AVAudioSettings.h
    var audioInputSetting: [String: Any]?
    var audioOutputSetting: [String: Any]?
    var audioMix: AVAudioMix?
    var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm?
}

// MARK: - Helper

fileprivate extension URL {
    static func temporaryExportURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".mp4"
        return documentDirectory.appendingPathComponent(filename)
    }
}
