import Foundation

enum Plist2HTML {

	private static let blankLine = "<br>"
	private static let ackKey = "PreferenceSpecifiers"
	private static let titleKey = "Title"
	private static let licenseKey = "License"
	private static let footerKey = "FooterText"

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

	// MARK: - Helpers

	private static func body(with content: String) -> String {
		let fullBody = ("<body>" + content + "</body>")

		let style = """
		<style> html, body { font-family: Calibri, "PT Sans", sans-serif; padding: 15px; }
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

	private static func header(with title: String) -> String {
		return ("<h1>" + title + "</h1>")
	}

	private static func subheader(with subtitle: String) -> String {
		return ("<h3>" + subtitle + "</h3>")
	}

	private static func paragraph(with text: String) -> String {
		return ("<p>" + text + "</p>")
	}
}
