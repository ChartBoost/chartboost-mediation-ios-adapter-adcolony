require_relative 'podspec_version'

PODSPEC_NAME_REGEX = /^\s*spec\.name\s*=\s*'([^']+)'\s*$/
ADAPTER_VERSION_REGEX = /^\s*let adapterVersion\s*=\s*"([^"]+)".*$/

# Obtain the podspec file path
podspec_path = Dir.glob(PODSPEC_PATH_PATTERN).first
fail unless !podspec_path.nil?

# Obtain the adapter name from the podspec
podspec = File.read(podspec_path)
pod_name = podspec.match(PODSPEC_NAME_REGEX).captures.first
fail unless !pod_name.nil?

# Obtain the partner name
partner_name = pod_name.delete_prefix "ChartboostMediationAdapter"
fail unless !partner_name.nil?

# Obtain the Adapter file path
file = Dir.glob("./Source/#{partner_name}Adapter.swift").first
fail unless !file.nil?

# Obtain the adapter version from the Adapter file
text = File.read(file)
adapter_version = text.match(ADAPTER_VERSION_REGEX).captures.first
fail unless !adapter_version.nil?

# Output match result to console
puts podspec_version == adapter_version
