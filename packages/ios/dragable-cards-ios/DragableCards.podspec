require "json"

# The version comes from item.json, the single source (the mirror sync tags the repo with the same value).
version = JSON.parse(File.read(File.join(__dir__, "item.json")))["version"]

Pod::Spec.new do |s|
  s.name         = "DragableCards"
  s.version      = version
  s.summary      = "A Trello-style board for SwiftUI: long-press a card, drag it between columns, snap it into place."
  s.homepage     = "https://github.com/ismnoiet/repgem-catalog/tree/main/packages/ios/dragable-cards-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ismnoiet" => "ismnoiet@users.noreply.github.com" }

  s.platform     = :ios, "17.0"
  s.swift_version = "5.9"

  s.source       = {
    :git => "https://github.com/ismnoiet/dragable-cards-ios.git",
    :tag => "#{s.version}"
  }

  s.source_files = "Sources/DragableCards/**/*.swift"
  s.frameworks   = "SwiftUI"
end
