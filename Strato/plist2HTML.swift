enum Plist2HTML {

	private static let whiteHTMLColor = "white"
	private static let blackHTMLColor = "black"

	static let blankLine = "<br>"
	static let ackKey = "PreferenceSpecifiers"
	static let titleKey = "Title"
	static let licenseKey = "License"
	static let footerKey = "FooterText"

	static func body(with content: String) -> String {
		let color = Plist2HTML.blackHTMLColor
		let fullBody = ("<body style=\"background-color:\(color);\">" + content + "</body>")

		let style = """
		  <style> html, body { font-family: Calibri,\"PT Sans\",sans-serif; padding: 15px; }
			  ol {
				  padding-left: 15px;
			  }
			  li {
				  font-size: 16px;
			  }
			  @media (prefers-color-scheme: dark) {
				  body {
					  background: #333;
					  color: #fff;
				  }
				  a {
					  color:#999;
				  }
			  }
		  </style>
		"""

		return (fullBody + style)
	}

	static func header(with title: String) -> String {
		let color = Plist2HTML.whiteHTMLColor
		return ("<h1 style=\"color:\(color);\">" + title + "</h1>")
	}

	static func subheader(with subtitle: String) -> String {
		let color = Plist2HTML.whiteHTMLColor
		return ("<h3 style=\"color:\(color);\">" + subtitle + "</h3>")
	}

	static func paragraph(with text: String) -> String {
		let color = Plist2HTML.whiteHTMLColor
		return ("<p style=\"color:\(color);\">" + text + "</p>")
	}

	/// Transforms the plist file containing the acknowledgments into an HTML
	/// - Parameter url: URL pointing to acknowledgments file
	static func transformPlistFile(from url: URL) -> String {
		guard
			let plistDict = NSDictionary(contentsOfFile: url.path),
			let acknowledgmentsMultiList = plistDict[Plist2HTML.ackKey] as? NSArray else {
				return ""
		}

		var htmlString = ""

		acknowledgmentsMultiList.forEach { (acknowledgment: Any) in

			guard let ackDict = acknowledgment as? NSDictionary else {
				return
			}

			if let _title = ackDict[Plist2HTML.titleKey] as? String {
				htmlString += Plist2HTML.header(with: _title)
			}

			if let _license = ackDict[Plist2HTML.licenseKey] as? String {
				htmlString += Plist2HTML.subheader(with: _license)
			}

			if let _footerText = ackDict[Plist2HTML.footerKey] as? String {
				htmlString += Plist2HTML.paragraph(with: _footerText.replacingOccurrences(of: "\n", with: Plist2HTML.blankLine))
			}

			htmlString += Plist2HTML.blankLine
		}

		return Plist2HTML.body(with: htmlString)
	}
}
