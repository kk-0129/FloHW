// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FloHW",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FloHW",
            targets: ["FloHW"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path:"../FloBox"),
        //.package(url:"https://github.com/uraimo/SwiftyGPIO.git",from:"1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FloHW",
            dependencies: [
                "FloBox",
                //.product(name:"SwiftyGPIO", package:"SwiftyGPIO")
            ]),
        .testTarget(
            name: "FloHWTests",
            dependencies: [
                "FloHW",
                "FloBox",
                //.product(name:"SwiftyGPIO", package:"SwiftyGPIO")
            ]),
    ]
)
