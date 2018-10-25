
target "iParapheur" do
  platform :ios, '8.0'
  use_frameworks!

  pod 'Fabric'
  pod 'Crashlytics'
  pod 'SCNetworkReachability'
  pod 'Alamofire', '~> 4.7'
  pod 'SwiftMessages'
  pod 'NSData+Base64'
  pod 'OpenSSL-Universal', '1.0.2.13'
  pod 'AEXML'
  pod 'SSZipArchive'
  pod 'CryptoSwift'

  target 'iParapheurTests' do
    inherit! :search_paths
  end

end
