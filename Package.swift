// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AxiomSideMenu",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "AxiomSideMenu",
      targets: ["AxiomSideMenu"]
    )
  ],
  targets: [
    .target(name: "AxiomSideMenu"),
    .testTarget(
      name: "AxiomSideMenuTests",
      dependencies: ["AxiomSideMenu"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
