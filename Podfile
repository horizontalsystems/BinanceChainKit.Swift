platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'BinanceChainKit'

project 'Demo/Demo'
project 'BinanceChainKit/BinanceChainKit'

def internal_pods
  pod 'HSCryptoKit', '~> 1.4'
  pod 'HSHDWalletKit', '~> 1.1'
end

target :BinanceChainKit do
  project 'BinanceChainKit/BinanceChainKit'
  internal_pods
end

target :Demo do
    project 'Demo/Demo'
    internal_pods
end

def test_pods
  pod 'Quick'
  pod 'Nimble'
  pod 'Cuckoo'
  pod 'RxBlocking', '~> 5.0'
end

target :BinanceChainKitTests do
  project 'BinanceChainKit/BinanceChainKit'

  internal_pods
  test_pods
end
