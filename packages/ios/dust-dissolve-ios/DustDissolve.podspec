require "json"

# The version comes from item.json, the single source (the mirror sync tags the repo with the same value).
version = JSON.parse(File.read(File.join(__dir__, "item.json")))["version"]

Pod::Spec.new do |s|
  s.name         = "DustDissolve"
  s.version      = version
  s.summary      = "A coupon that turns to dust and flows into the total (Metal shader + SwiftUI Canvas)."
  s.homepage     = "https://github.com/ismnoiet/repgem-catalog/tree/main/packages/ios/dust-dissolve-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ismnoiet" => "ismnoiet@users.noreply.github.com" }

  # colorEffect / visualEffect shaders require iOS 17+
  s.platform     = :ios, "17.0"
  s.swift_version = "5.9"

  s.source       = {
    :git => "https://github.com/ismnoiet/dust-dissolve-ios.git",
    :tag => "#{s.version}"
  }

  s.source_files = "Sources/DustDissolve/**/*.{swift,metal}"
  s.frameworks   = "SwiftUI"
end
