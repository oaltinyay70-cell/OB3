import Foundation
import CoreImage
import AppKit
import UniformTypeIdentifiers

let inPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]

guard let url = URL(fileURLWithPath: inPath) as URL?,
      let image = CIImage(contentsOf: url) else { exit(1) }

let size = 64
var cubeData = [Float](repeating: 0, count: size * size * size * 4)

var offset = 0
for z in 0..<size {
    for y in 0..<size {
        for x in 0..<size {
            let r = Float(x) / Float(size - 1)
            let g = Float(y) / Float(size - 1)
            let b = Float(z) / Float(size - 1)
            let a: Float = (r > 0.9 && g > 0.9 && b > 0.9) ? 0.0 : 1.0
            
            cubeData[offset] = r * a
            cubeData[offset+1] = g * a
            cubeData[offset+2] = b * a
            cubeData[offset+3] = a
            offset += 4
        }
    }
}

let data = Data(bytes: cubeData, count: cubeData.count * 4)
let colorCube = CIFilter(name: "CIColorCube")!
colorCube.setValue(size, forKey: "inputCubeDimension")
colorCube.setValue(data, forKey: "inputCubeData")
colorCube.setValue(image, forKey: kCIInputImageKey)

guard let output = colorCube.outputImage else { exit(1) }

let context = CIContext(options: nil)
guard let cgImage = context.createCGImage(output, from: output.extent) else { exit(1) }

let destUrl = URL(fileURLWithPath: outPath)
let dest = CGImageDestinationCreateWithURL(destUrl as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, cgImage, nil)
CGImageDestinationFinalize(dest)
