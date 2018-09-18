# Plist2Swift

Plist2swift generates swift code from given plist files. It will gather keys that are common for all plist and generate a protocol out of them. Keys that are unique to a plist will be added as optionals and a default implementation will be provided in extensions.

#### Note

   - <mark>*configurationName*</mark> key has to be added to the plist
   - Date and Data are not (yet) supported

### TODO

- [ ] Nested Dictionary support


## Example

Given plist A and plist B, we can generate swift code like so:

`swift Plist2swift.swift A.plist B.plist`

Now let's take a look into the plists and the generated code.

Plist A:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>configurationName</key>
	<string>Alpha</string>
	<key>privateKey</key>
	<string>fsfhor4hrbih13r938ryafsdofbo1urb1 balblala</string>
	<key>inAlpha</key>
	<string>This is only in Alpha</string>
	<key>shouldSign</key>
	<true/>
	<key>numberItem</key>
	<integer>123</integer>
	<key>dateItem</key>
	<date>2018-09-11T08:10:30Z</date>
	<key>anotherDict</key>
	<dict>
		<key>secretKey</key>
		<string>vnoethoiu3thoufhaksfbksefgb;eagb;oaghkdjfbna;e</string>
		<key>accessToken</key>
		<string>soivhawr;ovgubljkvbxcnzsbv.ksjbvkfjbv</string>
	</dict>
	<key>onlyinAlphaDict</key>
	<dict>
		<key>completelyPrivateKey</key>
		<string>aaaaaaaaaaaaaaaaaaaaaaaaaa</string>
	</dict>
	<key>alphaArray</key>
	<array>
		<string>Ala</string>
		<string>ma</string>
		<string>gruźlicę</string>
	</array>
</dict>
</plist>
```

Plist B:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>configurationName</key>
	<string>Beta</string>
	<key>inBeta</key>
	<string>This string is not in Alpha, only in Beta</string>
	<key>privateKey</key>
	<string>fdfsfsgfdgeqwerwfredvzxcw</string>
	<key>shouldSign</key>
	<false/>
	<key>numberItem</key>
	<integer>456</integer>
	<key>dateItem</key>
	<date>2018-09-11T08:10:30Z</date>
	<key>anotherDict</key>
	<dict>
		<key>secretKey</key>
		<string>uwrhfiusdbfvjhdsvhgavcayrtwdcatydfawufgla</string>
		<key>accessToken</key>
		<string>ascgsduycgauwygfuicblzsivclaweucvgalwc</string>
	</dict>
</dict>
</plist>
```

Generated Swift Code:

```
//
// Generated by plist2swift - Swift code from plists generator
//
// Generated on: 2018-09-18 09:09:42 +0000
//

import Foundation

protocol OnlyinAlphaDictProtocol {
	var completelyPrivateKey: String { get }
}
protocol AnotherDictProtocol {
	var secretKey: String { get }
	var accessToken: String { get }
}
protocol ApiProtocol {
	// Common Keys
	var anotherDict: AnotherDictProtocol { get }
	var shouldSign: Bool { get }
	var dateItem: String { get }
	var numberItem: Int { get }
	var configurationName: String { get }
	var privateKey: String { get }
	// Optional Keys
	var inAlpha: String? { get }
	var inBeta: String? { get }
	var onlyinAlphaDict: OnlyinAlphaDictProtocol? { get }
	var alphaArray: Array<Any>? { get }
}


internal enum Api {
	case alpha
	internal struct AlphaStruct {
	internal let dateItem: String = "2018-09-11 08:10:30 +0000"
	internal let numberItem: Int = 123
	internal let privateKey: String = "fsfhor4hrbih13r938ryafsdofbo1urb1 balblala"
	internal let configurationName: String = "Alpha"
	internal struct AnotherDictStruct: AnotherDictProtocol {
		internal let secretKey: String = "vnoethoiu3thoufhaksfbksefgb;eagb;oaghkdjfbna;e"
		internal let accessToken: String = "soivhawr;ovgubljkvbxcnzsbv.ksjbvkfjbv"
	}
	internal let anotherDict: AnotherDictProtocol = AnotherDictStruct()
	internal let shouldSign: Bool = true
	}
	case beta
	internal struct BetaStruct {
	internal let dateItem: String = "2018-09-11 08:10:30 +0000"
	internal let numberItem: Int = 456
	internal let privateKey: String = "fdfsfsgfdgeqwerwfredvzxcw"
	internal let configurationName: String = "Beta"
	internal struct AnotherDictStruct: AnotherDictProtocol {
		internal let secretKey: String = "uwrhfiusdbfvjhdsvhgavcayrtwdcatydfawufgla"
		internal let accessToken: String = "ascgsduycgauwygfuicblzsivclaweucvgalwc"
	}
	internal let anotherDict: AnotherDictProtocol = AnotherDictStruct()
	internal let shouldSign: Bool = false
	}

	var configuration: ApiProtocol {
		switch self {
		case .alpha:
			return AlphaStruct()
		case .beta:
			return BetaStruct()
		}
	}
}

extension Api.AlphaStruct: ApiProtocol {
	var inAlpha: String? {
		return "This is only in Alpha"
	}
	var inBeta: String? {
		return nil
	}
	internal struct OnlyinAlphaDictStruct: OnlyinAlphaDictProtocol {
		internal let completelyPrivateKey: String = "aaaaaaaaaaaaaaaaaaaaaaaaaa"
	}
	var onlyinAlphaDict: OnlyinAlphaDictProtocol? {
		return OnlyinAlphaDictStruct()
	}
	var alphaArray: Array<Any>? {
		return ["Ala", "ma", "gruźlicę"]
	}
}

extension Api.BetaStruct: ApiProtocol {
	var inAlpha: String? {
		return nil
	}
	var inBeta: String? {
		return "This string is not in Alpha, only in Beta"
	}
	var onlyinAlphaDict: OnlyinAlphaDictProtocol? {
		return nil
	}
	var alphaArray: Array<Any>? {
		return nil
	}
}

```

### How to use the code

Let's print out a common key and two plist specific keys and see what happens

```
private func printConfig(config: Api) {
	let privateKey = config.configuration.privateKey
	let inAlpha = config.configuration.inAlpha
	let inBeta = config.configuration.inBeta
	let accessToken = config.configuration.anotherDict.accessToken
	let secretKey = config.configuration.anotherDict.secretKey
	let onlyAlphaDict = config.configuration.onlyinAlphaDict?.completelyPrivateKey
	print("\(config)\n\(privateKey)\n\(inAlpha)\n\(inBeta)\n\(secretKey)\n\(accessToken)\nCompletely Private \(onlyAlphaDict)")
}

printConfig(config: Api.alpha)
printConfig(config: Api.beta)

```

Returns:

```
alpha
fsfhor4hrbih13r938ryafsdofbo1urb1 balblala
Optional("This is only in Alpha")
nil
vnoethoiu3thoufhaksfbksefgb;eagb;oaghkdjfbna;e
soivhawr;ovgubljkvbxcnzsbv.ksjbvkfjbv
Completely Private Optional("aaaaaaaaaaaaaaaaaaaaaaaaaa")

beta
fdfsfsgfdgeqwerwfredvzxcw
nil
Optional("This string is not in Alpha, only in Beta")
uwrhfiusdbfvjhdsvhgavcayrtwdcatydfawufgla
ascgsduycgauwygfuicblzsivclaweucvgalwc
Completely Private nil
```