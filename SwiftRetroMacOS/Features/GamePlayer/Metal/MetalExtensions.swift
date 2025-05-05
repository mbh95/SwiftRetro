//
//  MetalExtensions.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/23/25.
//

import MetalKit

extension MTLPixelFormat {
    func bytesPerPixel() -> Int {
        switch self {
        case .bgra8Unorm, .rgba8Unorm, .rgba8Sint, .bgra8Unorm_srgb,
            .rgba8Unorm_srgb:
            return 4
        case .r16Uint, .bgr5A1Unorm, .a1bgr5Unorm, .abgr4Unorm:
            return 2
        default:
            print("Warning: bytesPerPixel not defined for format \(self)")
            return 0
        }
    }
}
