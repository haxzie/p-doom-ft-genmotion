import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers

// usage: cutout in.png out.png
let args = CommandLine.arguments
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
guard let src = CIImage(contentsOf: inURL) else { fatalError("cannot read") }
let handler = VNImageRequestHandler(ciImage: src)
let req = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([req])
guard let result = req.results?.first else { fatalError("no subject") }
let maskBuf = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
let mask = CIImage(cvPixelBuffer: maskBuf)
let f = CIFilter.blendWithMask()
f.inputImage = src
f.backgroundImage = CIImage.empty()
f.maskImage = mask
let out = f.outputImage!
let ctx = CIContext()
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let cg = ctx.createCGImage(out, from: src.extent, format: .RGBA8, colorSpace: cs) else { fatalError("render") }
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, cg, nil)
CGImageDestinationFinalize(dest)
print("ok", args[2])
