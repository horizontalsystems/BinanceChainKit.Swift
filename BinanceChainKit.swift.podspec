Pod::Spec.new do |spec|
  spec.name = 'BinanceChainKit.swift'
  spec.module_name = 'BinanceChainKit'
  spec.version = '0.1'
  spec.summary = 'Binance blockchain library for Swift'
  spec.description = <<-DESC
                       BinanceChainKit.swift implements BinanceChain protocol in Swift.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/binance-chain-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/binance-chain-kit-ios.git', tag: "#{spec.version}" }
  spec.source_files = 'BinanceChainKit/BinanceChainKit/**/*.{h,m,swift}'
  spec.ios.deployment_target = '12.0'
  spec.swift_version = '5'

  spec.dependency 'HSCryptoKit', '~> 1.5'
  spec.dependency 'HSHDWalletKit', '~> 1.1'

  spec.dependency 'RxSwift', '~> 5.0'
  spec.dependency 'GRDB.swift', '~> 4.0'
  spec.dependency 'Alamofire', '~> 4.0'

  spec.dependency 'SwiftProtobuf', '~> 1.6'
  spec.dependency 'SwiftyJSON', '~> 4.3'
end
