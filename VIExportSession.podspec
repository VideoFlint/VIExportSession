Pod::Spec.new do |s|

    s.name = 'VIExportSession'
    s.version = '0.1'
    s.summary = 'VIExportSession is a AVAssetExportSession drop-in replacement with customizable audio&video settings.'

    s.license = { :type => "MIT", :file => "LICENSE" }

    s.homepage = 'https://github.com/VideoFlint/VIExportSession'

    s.author = { 'Vito' => 'vvitozhang@gmail.com' }

    s.platform = :ios, '9.0'
    s.swift_version = "4.0"

    s.source = { :git => 'https://github.com/VideoFlint/VIExportSession.git', :tag => s.version.to_s }
    s.source_files = 'VIExportSession/Source/*.{swift}'

    s.requires_arc = true
    s.frameworks = 'AVFoundation'

end

