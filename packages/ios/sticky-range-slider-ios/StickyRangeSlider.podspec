require "json"

# The version comes from item.json, the single source (the mirror sync tags the repo with the same value).
version = JSON.parse(File.read(File.join(__dir__, "item.json")))["version"]

Pod::Spec.new do |s|
  s.name         = "StickyRangeSlider"
  s.version      = version
  s.summary      = "A sticky, gooey range slider for SwiftUI: spring-following price pills that fuse into one."
  s.homepage     = "https://github.com/ismnoiet/repgem-catalog/tree/main/packages/ios/sticky-range-slider-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ismnoiet" => "ismnoiet@users.noreply.github.com" }

  # numericText transitions and sensoryFeedback require iOS 17+
  s.platform     = :ios, "17.0"
  s.swift_version = "5.9"

  s.source       = {
    :git => "https://github.com/ismnoiet/sticky-range-slider-ios.git",
    :tag => "#{s.version}"
  }

  s.source_files = "Sources/StickyRangeSlider/**/*.swift"
  s.frameworks   = "SwiftUI"
end
