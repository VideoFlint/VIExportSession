# VIExportSession

A `AVAssetExportSession` drop-in replacement with customizable audio&video settings.

You can get more control on video encode and decode, see the detail on `ExportConfiguration.swift`

```Swift
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
```

## Example

```
exportSession.videoConfiguration.videoOutputSetting = {
    let frameRate = 30
    let bitrate = min(2000000, videoTrack.estimatedDataRate)
    let trackDimensions = videoTrack.naturalSize
    let compressionSettings: [String: Any] = [
        AVVideoAverageNonDroppableFrameRateKey: frameRate,
        AVVideoAverageBitRateKey: bitrate,
        AVVideoMaxKeyFrameIntervalKey: 30,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]
    var videoSettings: [String : Any] = [
        AVVideoWidthKey: trackDimensions.width,
        AVVideoHeightKey: trackDimensions.height,
        AVVideoCompressionPropertiesKey: compressionSettings
    ]
    if #available(iOS 11.0, *) {
        videoSettings[AVVideoCodecKey] =  AVVideoCodecType.h264
    } else {
        videoSettings[AVVideoCodecKey] =  AVVideoCodecH264
    }
    return videoSettings
}()

exportSession.audioConfiguration.audioOutputSetting = {
    var stereoChannelLayout = AudioChannelLayout()
    memset(&stereoChannelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
    stereoChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
    
    let channelLayoutAsData = Data(bytes: &stereoChannelLayout, count: MemoryLayout<AudioChannelLayout>.size)
    let compressionAudioSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVEncoderBitRateKey: 128000,
        AVSampleRateKey: 44100,
        AVChannelLayoutKey: channelLayoutAsData,
        AVNumberOfChannelsKey: 2
    ]
    return compressionAudioSettings
}()
```

## Installation

`VIExportSession` only support Swift 4

**Cocoapods**

```
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
  # your other pod
  # ...
  pod 'VIExportSession'
end
```

**Manually**

You can simplely drag `VIExportSession.swift` to you project

## LICENSE

Under MIT
