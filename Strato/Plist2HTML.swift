import Foundation

struct Plist2HTML {

	enum HTMLStyle: String {
		case light
		case dark
	}

	private let style: HTMLStyle

	init(with style: HTMLStyle) {
		self.style = style
	}

	private static let whiteHTMLColor = "white"
	private static let blackHTMLColor = "black"

	private static let blankLine = "<br>"
	private static let ackKey = "PreferenceSpecifiers"
	private static let titleKey = "Title"
	private static let licenseKey = "License"
	private static let footerKey = "FooterText"

	private var textColor: String {
		return (self.style == .light) ? Plist2HTML.blackHTMLColor : Plist2HTML.whiteHTMLColor
	}

	private var backgroundColor: String {
		return (self.style == .light) ? Plist2HTML.whiteHTMLColor : Plist2HTML.blackHTMLColor
	}

	/// Transforms the plist file containing the acknowledgments into an HTML
	/// - Parameter url: URL pointing to acknowledgments file
	func transformPlistFile(from url: URL) -> String {
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
				htmlString += self.header(with: _title)
			}

			if let _license = ackDict[Plist2HTML.licenseKey] as? String {
				htmlString += self.subheader(with: _license)
			}

			if let _footerText = ackDict[Plist2HTML.footerKey] as? String {
				htmlString += self.paragraph(with: _footerText.replacingOccurrences(of: "\n", with: Plist2HTML.blankLine))
			}

			htmlString += Plist2HTML.blankLine
		}

		return self.body(with: htmlString)
	}

	// MARK: - Helpers

	private func body(with content: String) -> String {
		let fullBody = ("<body style=\"background-color:\(self.backgroundColor);\">" + content + "</body>")

		let style = """
		  <style> html, body { font-family: Calibri, "PT Sans", sans-serif; padding: 15px; }
			  ol {
				  padding-left: 15px;
			  }
			  li {
				  font-size: 16px;
			  }
		  </style>
		"""

		return (fullBody + style)
	}

	private func header(with title: String) -> String {
		return ("<h1 style=\"color:\(self.textColor);\">" + title + "</h1>")
	}

	private func subheader(with subtitle: String) -> String {
		return ("<h3 style=\"color:\(self.textColor);\">" + subtitle + "</h3>")
	}

	private func paragraph(with text: String) -> String {
		return ("<p style=\"color:\(self.textColor);\">" + text + "</p>")
	}
}
