require "json"

# The version comes from item.json, the single source (the mirror sync tags the repo with the same value).
version = JSON.parse(File.read(File.join(__dir__, "item.json")))["version"]

Pod::Spec.new do |s|
  s.name         = "FireworkFlourish"
  s.version      = version
  s.summary      = "Fireworks for any SwiftUI view: continuous or one-shot, with built-in styles and palettes."
  s.homepage     = "https://github.com/ismnoiet/repgem-catalog/tree/main/packages/ios/firework-flourish-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ismnoiet" => "ismnoiet@users.noreply.github.com" }

  # Canvas + TimelineView, onChange(of:) without a parameter: iOS 17+
  s.platform     = :ios, "17.0"
  s.swift_version = "5.9"

  s.source       = {
    :git => "https://github.com/ismnoiet/firework-flourish-ios.git",
    :tag => "#{s.version}"
  }

  s.source_files = "Sources/FireworkFlourish/**/*.swift"
  s.frameworks   = "SwiftUI"
end
