import Foundation
import Cocoa

let inPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let x = CGFloat((CommandLine.arguments[3] as NSString).doubleValue)
let y = CGFloat((CommandLine.arguments[4] as NSString).doubleValue)
let w = CGFloat((CommandLine.arguments[5] as NSString).doubleValue)
let h = CGFloat((CommandLine.arguments[6] as NSString).doubleValue)

guard let imgUrl = URL(fileURLWithPath: inPath) as URL? else { exit(1) }
guard let imgSource = CGImageSourceCreateWithURL(imgUrl as CFURL, nil) else { exit(1) }
guard let cgImage = CGImageSourceCreateImageAtIndex(imgSource, 0, nil) else { exit(1) }

let rect = CGRect(x: x, y: y, width: w, height: h)
let cropped = cgImage.cropping(to: rect)!

let destUrl = URL(fileURLWithPath: outPath)
let dest = CGImageDestinationCreateWithURL(destUrl as CFURL, kUTTypePNG, 1, nil)!
CGImageDestinationAddImage(dest, cropped, nil)
CGImageDestinationFinalize(dest)
