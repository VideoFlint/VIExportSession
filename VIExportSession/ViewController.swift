//
//  ViewController.swift
//  VIExportSession
//
//  Created by Vito on 30/01/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices

class ViewController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var fileInfoLabel: UILabel!
    
    private var exportSession: VIExportSession!
    
    fileprivate var pickedAsset: AVAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func addAction(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func exportAction(_ sender: UIButton) {
        guard let asset = pickedAsset else {
            return
        }
        exportSession = VIExportSession.init(asset: asset)
        
        if let track = asset.tracks(withMediaType: .video).first {
            configureExportConfiguration(videoTrack: track)
        }
        
        exportButton.isEnabled = false
        exportSession.progressHandler = { [weak self] (progress) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.progressView.progress = progress
                strongSelf.statusLabel.text = "Exporting \(Int(progress * 100))%"
            }
        }
        exportSession.completionHandler = { [weak self] (error) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    strongSelf.statusLabel.text = error.localizedDescription
                } else {
                    strongSelf.statusLabel.text = "Finished"
                    strongSelf.saveFileToPhotos(fileURL: strongSelf.exportSession.exportConfiguration.outputURL)
                }
                strongSelf.exportButton.isEnabled = true
            }
        }
        exportSession.export()
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        exportSession.cancelExport()
    }
    
    private func saveFileToPhotos(fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { [weak self] (saved, error) in
            guard let strongSelf = self else { return }
            if saved {
                let alertController = UIAlertController(title: "😀 Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                strongSelf.present(alertController, animated: true, completion: nil)
            } else {
                let errorMessage = error?.localizedDescription ?? ""
                let alertController = UIAlertController(title: "😢 Video can't save to Photos.app, error: \(errorMessage)", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                strongSelf.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Helper
    
    func configureExportConfiguration(videoTrack: AVAssetTrack) {
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
    }
    
    fileprivate func updatePickedAsset(_ asset: AVAsset) {
        pickedAsset = asset
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let width = UIScreen.main.bounds.width
        imageGenerator.maximumSize = CGSize(width: width, height: width)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: kCMTimeZero)]) { [weak self] (time, image, actualTime, result, error) in
            guard let strongSelf = self else { return }
            if let image = image {
                DispatchQueue.main.async {
                    strongSelf.coverImageView.backgroundColor = UIColor.clear
                    strongSelf.coverImageView.image = UIImage(cgImage: image)
                }
            } else {
                print("load thumb image failed")
                DispatchQueue.main.async {
                    strongSelf.coverImageView.backgroundColor = UIColor.red.withAlphaComponent(0.7)
                    strongSelf.coverImageView.image = nil
                }
            }
        }
        
        var infoText = "duration: \(String(format: "%.2f", asset.duration.seconds))"
        
        let size = asset.tracks(withMediaType: .video).first!.naturalSize
        infoText.append("\nresolution: \(size)")
        
        let framerate = asset.tracks(withMediaType: .video).first!.nominalFrameRate
        infoText.append("\nframerate: \(String(format: "%.2f", framerate))")
        
        let bitrate = asset.tracks(withMediaType: .video).first!.estimatedDataRate
        infoText.append("\nbitrate: \(String(format: "%.2f", bitrate / 1000))kb")
        
        let transform = asset.tracks(withMediaType: .video).first!.preferredTransform
        let angleDegress = atan2(transform.b, transform.a) * 180 / CGFloat.pi
        infoText.append("\nangle degress: \(String(format: "%.0f", angleDegress))")
        
        fileInfoLabel.text = infoText
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
            let asset = AVURLAsset(url: videoURL)
            updatePickedAsset(asset)
        }
    }
}

