require 'fileutils'

class Licences

	# target: pod target from the `Podfile`
	# path: the file's destination path
	def self.generateCleanAcknowledgementsPlist(target, path)
		puts "Generating acknowledgements with dependencies from " + target.name

		source = 'Pods/Target Support Files/' + target.name + '/' + target.name + '-acknowledgements.plist'
		FileUtils.cp_r(source, path, :remove_destination => true)
		
		expand_path = File.expand_path(path)
		
		# See https://smartmobilefactory.atlassian.net/browse/STRFRAMEWORK-2640
		`swift Submodules/SMF-iOS-CommonProjectSetupFiles/Strato/cleanLicences.swift #{expand_path}`
	end
	
end