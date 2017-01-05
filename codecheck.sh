cp Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/.swiftlint.yml ./
cp Submodules/SMF-iOS-CommonProjectSetupFiles/Codebeat/.codebeatignore ./
cp Submodules/SMF-iOS-CommonProjectSetupFiles/Codebeat/.codebeatsettings ./

if which swiftlint >/dev/null; then
swiftlint
else
echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
fi

