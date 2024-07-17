// swift-tools-version: 5.10

import PackageDescription


let package = Package(
    name: "Task",
    products: [
        .library(
            name: "Task",
            targets: ["Task"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/prachigauriar/URLMock.git", from: "1.3.6"),
    ],
    targets: [
        .target(
            name: "Task"
        ),
        .testTarget(
            name: "TaskTests",
            dependencies: [
                "Task",
                "URLMock"
            ]
        ),
    ]
)
