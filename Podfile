platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'BinanceChainKit'

project 'Demo/Demo'
project 'BinanceChainKit/BinanceChainKit'

def kit_pods
  pod 'HSCryptoKit', '~> 1.4'
  pod 'HSHDWalletKit', '~> 1.1'

  pod 'RxSwift'
  pod 'SwiftProtobuf', :inhibit_warnings => true
  pod 'Alamofire', '~> 4.0'
  pod 'SwiftyJSON', '~> 4.3'
  # pod 'BinanceChain', :git => 'https://github.com/mh7821/SwiftBinanceChain.git'
end

target :BinanceChainKit do
  project 'BinanceChainKit/BinanceChainKit'
  kit_pods
end

target :Demo do
  project 'Demo/Demo'
  kit_pods
end

def test_pods
  pod 'Quick'
  pod 'Nimble'
  pod 'Cuckoo'
end

target :BinanceChainKitTests do
  project 'BinanceChainKit/BinanceChainKit'

  kit_pods
  test_pods
end
