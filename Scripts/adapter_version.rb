PODSPEC_PATH_PATTERN = "*.podspec"
PODSPEC_VERSION_REGEX = /^\s*spec\.version\s*=\s*'([0-9]+.[0-9]+.[0-9]+.[0-9]+.[0-9]+(?>.[0-9]+)?)'\s*$/

# Obtain the podspec file path
file = Dir.glob(PODSPEC_PATH_PATTERN).first
fail unless !file.nil?

# Obtain the adapter version from the podspec
text = File.read(file)
version = text.match(PODSPEC_VERSION_REGEX).captures.first
fail unless !version.nil?

# Output to console
puts version
