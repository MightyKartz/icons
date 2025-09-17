//
//  ExportService.swift
//  Icons
//
//  Created by Icons App on 2024/01/15.
//

import Foundation
import AppKit
import CoreGraphics
import UniformTypeIdentifiers
import Accelerate
import SwiftUI
import ImageIO

/// 图标导出服务
class ExportService: ObservableObject {
    
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - 导出方法
    
    /// 导出单个图标
    @MainActor
    func exportIcon(
        _ icon: GeneratedIcon,
        to url: URL,
        format: ExportFormat,
        size: CGSize? = nil,
        compressionQuality: Double? = nil,
        backgroundColor: Color? = nil,
        addPadding: Bool = false,
        paddingPercentage: Double = 0
    ) async throws {
        let image = try await loadImage(from: icon)
        guard let loadedImage = image else {
            throw ExportError.invalidImage
        }
        
        // 计算画布尺寸（最终导出尺寸）
        let canvasSize = size ?? loadedImage.size
        
        // 计算内边距后的目标尺寸
        let paddingPct = addPadding ? max(0.0, min(100.0, paddingPercentage)) / 100.0 : 0.0
        let innerWidth = max(1, canvasSize.width * (1.0 - 2.0 * paddingPct))
        let innerHeight = max(1, canvasSize.height * (1.0 - 2.0 * paddingPct))
        let innerTargetSize = CGSize(width: innerWidth, height: innerHeight)
        
        // 将原图缩放至内层目标尺寸（保持比例，必要时在内层尺寸内等比留边）
        let resizedInner = try await resizeImage(loadedImage, to: innerTargetSize)
        
        // 在画布上合成（可选背景色）
        let finalImage = NSImage(size: canvasSize)
        finalImage.lockFocus()
        defer { finalImage.unlockFocus() }
        
        if let bg = backgroundColor, let nsBg = ExportService.nsColor(from: bg), nsBg.alphaComponent > 0.0 {
            nsBg.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
        }
        
        let drawX = (canvasSize.width - resizedInner.size.width) / 2.0
        let drawY = (canvasSize.height - resizedInner.size.height) / 2.0
        resizedInner.draw(
            in: NSRect(x: drawX, y: drawY, width: resizedInner.size.width, height: resizedInner.size.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        
        try await saveImage(finalImage, to: url, format: format, compressionQuality: compressionQuality)
    }
    
    /// 批量导出图标
    @MainActor
    func exportIcons(
        _ icons: [GeneratedIcon],
        to directoryURL: URL,
        format: ExportFormat,
        size: CGSize? = nil,
        progressHandler: @escaping (Double) -> Void = { _ in }
    ) async throws {
        let totalCount = icons.count
        
        for (index, icon) in icons.enumerated() {
            let fileName = "\(icon.id).\(format.fileExtension)"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            
            try await exportIcon(icon, to: fileURL, format: format, size: size)
            
            let progress = Double(index + 1) / Double(totalCount)
            await MainActor.run {
                progressHandler(progress)
            }
        }
    }
    
    /// 导出为 App Icon Set
    @MainActor
    func exportAsAppIconSet(
        _ icon: GeneratedIcon,
        to directoryURL: URL,
        platform: AppIconPlatform = .iOS,
        compressionQuality: Double? = nil,
        backgroundColor: Color? = nil,
        addPadding: Bool = false,
        paddingPercentage: Double = 0
    ) async throws {
        let baseImage = try await loadImage(from: icon)
        guard let loadedBaseImage = baseImage else {
            throw ExportError.invalidImage
        }
        // 计算内边距百分比
        let paddingPct = addPadding ? max(0.0, min(100.0, paddingPercentage)) / 100.0 : 0.0
        
        // macOS 使用 .iconset 目录结构（供 iconutil 生成 .icns）
        if platform == .macOS {
            let baseName = ExportService.sanitizeFileName(icon.prompt.isEmpty ? icon.id.uuidString : icon.prompt)
            let iconsetURL = directoryURL.appendingPathComponent("\(baseName).iconset")
            try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
            
            let sizeSpecs = AppIconSizeSpec.getSizeSpecs(for: .macOS)
            for spec in sizeSpecs {
                let canvasSize = spec.pixelSize
                let innerSize = CGSize(
                    width: max(1, canvasSize.width * (1.0 - 2.0 * paddingPct)),
                    height: max(1, canvasSize.height * (1.0 - 2.0 * paddingPct))
                )
                let resizedInner = try await resizeImage(loadedBaseImage, to: innerSize)
                
                let composed = NSImage(size: canvasSize)
                composed.lockFocus()
                if let bg = backgroundColor, let nsBg = ExportService.nsColor(from: bg), nsBg.alphaComponent > 0.0 {
                    nsBg.setFill()
                    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
                }
                let drawX = (canvasSize.width - resizedInner.size.width) / 2.0
                let drawY = (canvasSize.height - resizedInner.size.height) / 2.0
                resizedInner.draw(
                    in: NSRect(x: drawX, y: drawY, width: resizedInner.size.width, height: resizedInner.size.height),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1.0
                )
                composed.unlockFocus()
                
                let filename = ExportService.macOSIconsetFilename(for: spec)
                let imageURL = iconsetURL.appendingPathComponent(filename)
                try await saveImage(composed, to: imageURL, format: .png, compressionQuality: compressionQuality)
            }
            return
        }
        
        // 其他平台生成 .appiconset + Contents.json
        let baseName = ExportService.sanitizeFileName(icon.prompt.isEmpty ? icon.id.uuidString : icon.prompt)
        let appIconSetURL = directoryURL.appendingPathComponent("\(baseName).appiconset")
        try FileManager.default.createDirectory(at: appIconSetURL, withIntermediateDirectories: true)
        
        let sizeSpecs = AppIconSizeSpec.getSizeSpecs(for: platform)
        
        let contentsJSON = generateContentsJSON(for: sizeSpecs, platform: platform)
        let contentsData = try JSONSerialization.data(withJSONObject: contentsJSON, options: .prettyPrinted)
        let contentsURL = appIconSetURL.appendingPathComponent("Contents.json")
        try contentsData.write(to: contentsURL)
        
        for spec in sizeSpecs {
            let canvasSize = spec.pixelSize
            let innerSize = CGSize(
                width: max(1, canvasSize.width * (1.0 - 2.0 * paddingPct)),
                height: max(1, canvasSize.height * (1.0 - 2.0 * paddingPct))
            )
            let resizedInner = try await resizeImage(loadedBaseImage, to: innerSize)
            
            let composed = NSImage(size: canvasSize)
            composed.lockFocus()
            if let bg = backgroundColor, let nsBg = ExportService.nsColor(from: bg), nsBg.alphaComponent > 0.0 {
                nsBg.setFill()
                NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
            }
            let drawX = (canvasSize.width - resizedInner.size.width) / 2.0
            let drawY = (canvasSize.height - resizedInner.size.height) / 2.0
            resizedInner.draw(
                in: NSRect(x: drawX, y: drawY, width: resizedInner.size.width, height: resizedInner.size.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
            composed.unlockFocus()
            
            let imageURL = appIconSetURL.appendingPathComponent(spec.filename)
            try await saveImage(composed, to: imageURL, format: .png, compressionQuality: compressionQuality)
        }
    }
    
    /// 导出为多种格式
    @MainActor
    func exportMultiFormat(
        _ icon: GeneratedIcon,
        to directoryURL: URL,
        formats: [ExportFormat],
        sizes: [CGSize] = []
    ) async throws {
        let baseImage = try await loadImage(from: icon)
        guard let loadedBaseImage = baseImage else {
            throw ExportError.invalidImage
        }
        
        let baseName = icon.prompt.replacingOccurrences(of: " ", with: "_")
        
        for format in formats {
            if sizes.isEmpty {
                // 导出原始尺寸
                let fileName = "\(baseName).\(format.fileExtension)"
                let fileURL = directoryURL.appendingPathComponent(fileName)
                try await saveImage(loadedBaseImage, to: fileURL, format: format)
            } else {
                // 导出多种尺寸
                for size in sizes {
                    let resizedImage = try await resizeImage(loadedBaseImage, to: size)
                    let fileName = "\(baseName)_\(Int(size.width))x\(Int(size.height)).\(format.fileExtension)"
                    let fileURL = directoryURL.appendingPathComponent(fileName)
                    try await saveImage(resizedImage, to: fileURL, format: format)
                }
            }
        }
    }
    
    // MARK: - 图像处理
    
    /// 从GeneratedIcon加载图像
    @MainActor
    private func loadImage(from icon: GeneratedIcon) async throws -> NSImage? {
        // 优先使用本地路径
        if let localPath = icon.localPath {
            let localURL = URL(fileURLWithPath: localPath)
            if FileManager.default.fileExists(atPath: localPath) {
                return NSImage(contentsOf: localURL)
            }
        }

        // 从URL下载图像
        guard let url = URL(string: icon.imageURL) else {
            throw ExportError.invalidImage
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return NSImage(data: data)
    }
    
    /// 高质量图像缩放
    @MainActor
    private func resizeImage(_ image: NSImage, to targetSize: CGSize) async throws -> NSImage {
        // 先在主线程上从 NSImage 提取 CGImage，避免在并发闭包中捕获 NSImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExportError.invalidImage
        }
        let resultCG: CGImage = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let outCG = try ExportService.performImageResizeCG(cgImage, to: targetSize)
                    continuation.resume(returning: outCG)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        return NSImage(cgImage: resultCG, size: targetSize)
    }

    /// 执行图像缩放（基于 CGImage，在后台线程安全运行）
    private static func performImageResizeCG(_ cgImage: CGImage, to targetSize: CGSize) throws -> CGImage {
        // 若目标尺寸与源尺寸一致，直接返回原图
        let sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
        if abs(sourceSize.width - targetSize.width) < 0.5 && abs(sourceSize.height - targetSize.height) < 0.5 {
            return cgImage
        }
        
        // 计算等比缩放后的尺寸（居中铺放）
        let scaleX = targetSize.width / sourceSize.width
        let scaleY = targetSize.height / sourceSize.height
        let scale = min(scaleX, scaleY)
        let scaledSize = CGSize(width: max(1, sourceSize.width * scale), height: max(1, sourceSize.height * scale))
        
        // vImage 缩放到 scaledSize，然后再居中绘制到 targetSize 画布
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(colorSpace),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        var sourceBuffer = vImage_Buffer()
        var scaledBuffer = vImage_Buffer()
        defer {
            free(sourceBuffer.data)
            free(scaledBuffer.data)
        }
        
        do {
            // 创建源 buffer
            var createSrcStatus = kvImageNoError
            createSrcStatus = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags))
            guard createSrcStatus == kvImageNoError else { throw ExportError.resizeFailed }
            
            // 创建目标（缩放后） buffer
            let scaledWidth = max(1, Int(scaledSize.width.rounded()))
            let scaledHeight = max(1, Int(scaledSize.height.rounded()))
            let initDstStatus = vImageBuffer_Init(&scaledBuffer, vImagePixelCount(scaledHeight), vImagePixelCount(scaledWidth), format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
            guard initDstStatus == kvImageNoError else { throw ExportError.resizeFailed }
            
            // 高质量重采样缩放
            let scaleStatus = vImageScale_ARGB8888(&sourceBuffer, &scaledBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
            guard scaleStatus == kvImageNoError else { throw ExportError.resizeFailed }
            
            // 将缩放后的 buffer 转 CGImage
            guard let scaledCGImage = vImageCreateCGImageFromBuffer(&scaledBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)?.takeRetainedValue() else {
                throw ExportError.resizeFailed
            }
            
            // 创建最终目标画布（targetSize），将缩放图置中绘制
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let context = CGContext(
                data: nil,
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                throw ExportError.resizeFailed
            }
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.interpolationQuality = .high
            
            // 透明背景（保持 alpha）
            context.clear(CGRect(origin: .zero, size: targetSize))
            
            // 计算居中 rect
            let x = (targetSize.width - CGFloat(scaledWidth)) / 2.0
            let y = (targetSize.height - CGFloat(scaledHeight)) / 2.0
            let drawRect = CGRect(x: x, y: y, width: CGFloat(scaledWidth), height: CGFloat(scaledHeight))
            context.draw(scaledCGImage, in: drawRect)
            
            guard let resultCGImage = context.makeImage() else {
                throw ExportError.resizeFailed
            }
            return resultCGImage
        } catch {
            // vImage 出错时回退到原有 CGContext 实现
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let context = CGContext(
                data: nil,
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                throw ExportError.resizeFailed
            }
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.interpolationQuality = .high
            
            let scaleX = targetSize.width / sourceSize.width
            let scaleY = targetSize.height / sourceSize.height
            let scale = min(scaleX, scaleY)
            let scaledSize = CGSize(width: max(1, sourceSize.width * scale), height: max(1, sourceSize.height * scale))
            let x = (targetSize.width - scaledSize.width) / 2
            let y = (targetSize.height - scaledSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
            context.draw(cgImage, in: drawRect)
            guard let resultCGImage = context.makeImage() else {
                throw ExportError.resizeFailed
            }
            return resultCGImage
        }
    }

    // 旧实现保留（未使用），如需可移除或迁移至 CGImage 版本
    /// 执行图像缩放
    private static func performImageResize(_ image: NSImage, to targetSize: CGSize) throws -> NSImage {
        // 若目标尺寸与源尺寸一致，直接返回
        let sourceSize = image.size
        if abs(sourceSize.width - targetSize.width) < 0.5 && abs(sourceSize.height - targetSize.height) < 0.5 {
            return image
        }
        
        // 计算等比缩放后的尺寸（居中铺放）
        let scaleX = targetSize.width / sourceSize.width
        let scaleY = targetSize.height / sourceSize.height
        let scale = min(scaleX, scaleY)
        let scaledSize = CGSize(width: max(1, sourceSize.width * scale), height: max(1, sourceSize.height * scale))
        
        // 源 CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExportError.invalidImage
        }
        
        // vImage 缩放到 scaledSize，然后再居中绘制到 targetSize 画布
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        // 选择 ARGB8888（premultipliedFirst）格式，便于使用 vImageScale_ARGB8888
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(colorSpace),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        var sourceBuffer = vImage_Buffer()
        var scaledBuffer = vImage_Buffer()
        defer {
            free(sourceBuffer.data)
            free(scaledBuffer.data)
        }
        
        do {
            // 创建源 buffer
            var createSrcStatus = kvImageNoError
            createSrcStatus = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags))
            guard createSrcStatus == kvImageNoError else { throw ExportError.resizeFailed }
            
            // 创建目标（缩放后） buffer
            let scaledWidth = max(1, Int(scaledSize.width.rounded()))
            let scaledHeight = max(1, Int(scaledSize.height.rounded()))
            let initDstStatus = vImageBuffer_Init(&scaledBuffer, vImagePixelCount(scaledHeight), vImagePixelCount(scaledWidth), format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
            guard initDstStatus == kvImageNoError else { throw ExportError.resizeFailed }
            
            // 高质量重采样缩放
            let scaleStatus = vImageScale_ARGB8888(&sourceBuffer, &scaledBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
            guard scaleStatus == kvImageNoError else { throw ExportError.resizeFailed }
            
            // 将缩放后的 buffer 转 CGImage
            guard let scaledCGImage = vImageCreateCGImageFromBuffer(&scaledBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)?.takeRetainedValue() else {
                throw ExportError.resizeFailed
            }
            
            // 创建最终目标画布（targetSize），将缩放图置中绘制
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let context = CGContext(
                data: nil,
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                throw ExportError.resizeFailed
            }
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.interpolationQuality = .high
            
            let scaleX = targetSize.width / sourceSize.width
            let scaleY = targetSize.height / sourceSize.height
            let scale = min(scaleX, scaleY)
            let scaledSize = CGSize(width: max(1, sourceSize.width * scale), height: max(1, sourceSize.height * scale))
            let x = (targetSize.width - scaledSize.width) / 2
            let y = (targetSize.height - scaledSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
            context.draw(scaledCGImage, in: drawRect)
            guard let resultCGImage = context.makeImage() else {
                throw ExportError.resizeFailed
            }
            return NSImage(cgImage: resultCGImage, size: targetSize)
        }
    }

    /// 保存图像到文件
    private func saveImage(_ image: NSImage, to url: URL, format: ExportFormat, compressionQuality: Double? = nil) async throws {
        // 在主线程提取 CGImage，避免在并发闭包中捕获 NSImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExportError.invalidImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try ExportService.performImageSave(cgImage: cgImage, to: url, format: format, compressionQuality: compressionQuality)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 执行图像保存（基于 CGImage，在后台线程安全运行）
    private static func performImageSave(cgImage: CGImage, to url: URL, format: ExportFormat, compressionQuality: Double? = nil) throws {
        switch format {
        case .png:
            // 使用 ImageIO 写入 PNG
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                throw ExportError.saveFailed
            }
            // PNG 一般不使用有损压缩质量参数，忽略 compressionQuality
            CGImageDestinationAddImage(dest, cgImage, nil)
            if !CGImageDestinationFinalize(dest) {
                throw ExportError.saveFailed
            }
        case .ico:
            // 先生成 PNG 数据，再封装为 ICO
            let pngData = try createPNGData(from: cgImage)
            let icoData = try createICOData(fromPNGData: pngData, cgImage: cgImage)
            try icoData.write(to: url)
        case .svg, .pdf, .icns:
            throw ExportError.unsupportedFormat
        }
    }

    /// 生成 PNG 数据（使用 ImageIO）
    private static func createPNGData(from cgImage: CGImage) throws -> Data {
        let data = CFDataCreateMutable(nil, 0)!
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ExportError.saveFailed
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        if !CGImageDestinationFinalize(dest) {
            throw ExportError.saveFailed
        }
        return data as Data
    }

    /// 创建 ICO 格式数据（基于 PNG 数据与图像尺寸）
    private static func createICOData(fromPNGData pngData: Data, cgImage: CGImage) throws -> Data {
        var icoData = Data()
        
        // ICO 文件头
        icoData.append(contentsOf: [0x00, 0x00]) // Reserved
        icoData.append(contentsOf: [0x01, 0x00]) // Type (1 = ICO)
        icoData.append(contentsOf: [0x01, 0x00]) // Number of images
        
        // 图像目录条目
        let width = min(cgImage.width, 255)
        let height = min(cgImage.height, 255)
        
        icoData.append(UInt8(width == 256 ? 0 : width))   // Width
        icoData.append(UInt8(height == 256 ? 0 : height)) // Height
        icoData.append(0x00) // Color palette (0 = no palette)
        icoData.append(0x00) // Reserved
        icoData.append(contentsOf: [0x01, 0x00]) // Color planes
        icoData.append(contentsOf: [0x20, 0x00]) // Bits per pixel (32)
        
        let imageSize = UInt32(pngData.count)
        let headerSize = 6 + 16 // ICO header (6) + dir entry (16)
        let imageOffset = UInt32(headerSize)
        
        icoData.append(contentsOf: withUnsafeBytes(of: imageSize.littleEndian, Array.init)) // Size of image data
        icoData.append(contentsOf: withUnsafeBytes(of: imageOffset.littleEndian, Array.init)) // Offset to image data
        
        // 图像数据（PNG 数据）
        icoData.append(pngData)
        
        return icoData
    }
    
    // MARK: - App Icon Set 支持
    
    /// 生成 Contents.json（从 AppIconSizeSpec 配置驱动的 sizeSpecs 构造）
    /// 优先读取 Bundle.main(Resources/icon-sizes.json)，开发环境可放置到 Application Support 目录替换，失败则回退到内置表。
    func generateContentsJSON(for sizeSpecs: [AppIconSizeSpec], platform: AppIconPlatform) -> [String: Any] {
        let images = sizeSpecs.map { spec in
            return [
                "filename": spec.filename,
                "idiom": spec.idiom,
                "scale": spec.scale,
                "size": spec.size
            ]
        }
        
        return [
            "images": images,
            "info": [
                "author": "Icons App",
                "version": 1
            ]
        ]
    }
}

// MARK: - 数据模型

/// 导出错误
enum ExportError: LocalizedError {
    case invalidImage
    case resizeFailed
    case saveFailed
    case unsupportedFormat
    case fileSystemError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图像数据"
        case .resizeFailed:
            return "图像缩放失败"
        case .saveFailed:
            return "文件保存失败"
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .fileSystemError:
            return "文件系统错误"
        }
    }
}

/// App Icon 平台
enum AppIconPlatform: String, CaseIterable {
    case iOS = "ios"
    case macOS = "macos"
    case watchOS = "watchos"
    case tvOS = "tvos"
    
    var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .watchOS: return "watchOS"
        case .tvOS: return "tvOS"
        }
    }
    
    var sizeSpecs: [AppIconSizeSpec] {
        return AppIconSizeSpec.getSizeSpecs(for: self)
    }
}

/// App Icon 尺寸规格
struct AppIconSizeSpec: Codable {
    let size: String
    let scale: String
    let idiom: String
    let filename: String

    // 运行时缓存配置，避免重复读取
    private static var cachedConfig: [String: [AppIconSizeSpec]]?

    // 从配置读取指定平台的尺寸规格；若失败则返回 nil
    private static func loadFromConfig(for platform: AppIconPlatform) -> [AppIconSizeSpec]? {
        // 若已有缓存，直接返回
        if let cached = cachedConfig?[platform.rawValue], !cached.isEmpty {
            return cached
        }
        // 首先尝试从应用 Bundle 读取
        var data: Data?
        if let url = Bundle.main.url(forResource: "icon-sizes", withExtension: "json") {
            data = try? Data(contentsOf: url)
        } else {
            // 开发场景兜底：尝试从应用支持目录读取（便于本地调试替换配置）
            if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let fileURL = supportURL.appendingPathComponent("icon-sizes.json")
                data = try? Data(contentsOf: fileURL)
            }
        }
        guard let jsonData = data else { return nil }

        // 解析为 [String: [[String: Any]]] 并手动映射为 AppIconSizeSpec，避免定义固定键的 Decodable 结构
        do {
            let raw = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let dict = raw as? [String: Any] else { return nil }
            var result: [String: [AppIconSizeSpec]] = [:]
            for (key, value) in dict {
                guard let arr = value as? [[String: Any]] else { continue }
                let specs: [AppIconSizeSpec] = arr.compactMap { item in
                    guard let size = item["size"] as? String,
                          let scale = item["scale"] as? String,
                          let idiom = item["idiom"] as? String,
                          let filename = item["filename"] as? String else {
                        return nil
                    }
                    return AppIconSizeSpec(size: size, scale: scale, idiom: idiom, filename: filename)
                }
                if !specs.isEmpty {
                    result[key.lowercased()] = specs
                }
            }
            cachedConfig = result
            return result[platform.rawValue]
        } catch {
            return nil
        }
    }

    var pixelSize: CGSize {
        let components = size.split(separator: "x")
        guard components.count == 2,
              let width = Double(components[0]),
              let height = Double(components[1]),
              let scaleValue = Double(scale.replacingOccurrences(of: "x", with: "")) else {
            return CGSize(width: 60, height: 60)
        }
        
        return CGSize(width: width * scaleValue, height: height * scaleValue)
    }
    
    /// 获取平台对应的尺寸规格（优先从配置读取）
    static func getSizeSpecs(for platform: AppIconPlatform) -> [AppIconSizeSpec] {
        if let specs = loadFromConfig(for: platform), !specs.isEmpty {
            return specs
        }
        // 配置缺失或解析失败时回退至内置默认表
        switch platform {
        case .iOS:
            return iOSSizeSpecs
        case .macOS:
            return macOSSizeSpecs
        case .watchOS:
            return watchOSSizeSpecs
        case .tvOS:
            return tvOSSizeSpecs
        }
    }

    // MARK: - iOS 尺寸规格

    private static let iOSSizeSpecs: [AppIconSizeSpec] = [
        // iPhone
        AppIconSizeSpec(size: "20x20", scale: "2x", idiom: "iphone", filename: "Icon-20@2x.png"),
        AppIconSizeSpec(size: "20x20", scale: "3x", idiom: "iphone", filename: "Icon-20@3x.png"),
        AppIconSizeSpec(size: "29x29", scale: "2x", idiom: "iphone", filename: "Icon-29@2x.png"),
        AppIconSizeSpec(size: "29x29", scale: "3x", idiom: "iphone", filename: "Icon-29@3x.png"),
        AppIconSizeSpec(size: "40x40", scale: "2x", idiom: "iphone", filename: "Icon-40@2x.png"),
        AppIconSizeSpec(size: "40x40", scale: "3x", idiom: "iphone", filename: "Icon-40@3x.png"),
        AppIconSizeSpec(size: "60x60", scale: "2x", idiom: "iphone", filename: "Icon-60@2x.png"),
        AppIconSizeSpec(size: "60x60", scale: "3x", idiom: "iphone", filename: "Icon-60@3x.png"),
        
        // iPad
        AppIconSizeSpec(size: "20x20", scale: "1x", idiom: "ipad", filename: "Icon-20.png"),
        AppIconSizeSpec(size: "20x20", scale: "2x", idiom: "ipad", filename: "Icon-20@2x~ipad.png"),
        AppIconSizeSpec(size: "29x29", scale: "1x", idiom: "ipad", filename: "Icon-29.png"),
        AppIconSizeSpec(size: "29x29", scale: "2x", idiom: "ipad", filename: "Icon-29@2x~ipad.png"),
        AppIconSizeSpec(size: "40x40", scale: "1x", idiom: "ipad", filename: "Icon-40.png"),
        AppIconSizeSpec(size: "40x40", scale: "2x", idiom: "ipad", filename: "Icon-40@2x~ipad.png"),
        AppIconSizeSpec(size: "76x76", scale: "1x", idiom: "ipad", filename: "Icon-76.png"),
        AppIconSizeSpec(size: "76x76", scale: "2x", idiom: "ipad", filename: "Icon-76@2x.png"),
        AppIconSizeSpec(size: "83.5x83.5", scale: "2x", idiom: "ipad", filename: "Icon-83.5@2x.png"),
        
        // App Store
        AppIconSizeSpec(size: "1024x1024", scale: "1x", idiom: "ios-marketing", filename: "Icon-1024.png")
    ]
    
    // MARK: - macOS 尺寸规格
    
    private static let macOSSizeSpecs: [AppIconSizeSpec] = [
        AppIconSizeSpec(size: "16x16", scale: "1x", idiom: "mac", filename: "Icon-16.png"),
        AppIconSizeSpec(size: "16x16", scale: "2x", idiom: "mac", filename: "Icon-16@2x.png"),
        AppIconSizeSpec(size: "32x32", scale: "1x", idiom: "mac", filename: "Icon-32.png"),
        AppIconSizeSpec(size: "32x32", scale: "2x", idiom: "mac", filename: "Icon-32@2x.png"),
        AppIconSizeSpec(size: "128x128", scale: "1x", idiom: "mac", filename: "Icon-128.png"),
        AppIconSizeSpec(size: "128x128", scale: "2x", idiom: "mac", filename: "Icon-128@2x.png"),
        AppIconSizeSpec(size: "256x256", scale: "1x", idiom: "mac", filename: "Icon-256.png"),
        AppIconSizeSpec(size: "256x256", scale: "2x", idiom: "mac", filename: "Icon-256@2x.png"),
        AppIconSizeSpec(size: "512x512", scale: "1x", idiom: "mac", filename: "Icon-512.png"),
        AppIconSizeSpec(size: "512x512", scale: "2x", idiom: "mac", filename: "Icon-512@2x.png")
    ]
    
    // MARK: - watchOS 尺寸规格
    
    private static let watchOSSizeSpecs: [AppIconSizeSpec] = [
        AppIconSizeSpec(size: "24x24", scale: "2x", idiom: "watch", filename: "Icon-24@2x.png"),
        AppIconSizeSpec(size: "27.5x27.5", scale: "2x", idiom: "watch", filename: "Icon-27.5@2x.png"),
        AppIconSizeSpec(size: "29x29", scale: "2x", idiom: "watch", filename: "Icon-29@2x.png"),
        AppIconSizeSpec(size: "29x29", scale: "3x", idiom: "watch", filename: "Icon-29@3x.png"),
        AppIconSizeSpec(size: "40x40", scale: "2x", idiom: "watch", filename: "Icon-40@2x.png"),
        AppIconSizeSpec(size: "44x44", scale: "2x", idiom: "watch", filename: "Icon-44@2x.png"),
        AppIconSizeSpec(size: "50x50", scale: "2x", idiom: "watch", filename: "Icon-50@2x.png"),
        AppIconSizeSpec(size: "1024x1024", scale: "1x", idiom: "watch-marketing", filename: "Icon-1024.png")
    ]
    
    // MARK: - tvOS 尺寸规格
    
    private static let tvOSSizeSpecs: [AppIconSizeSpec] = [
        AppIconSizeSpec(size: "400x240", scale: "1x", idiom: "tv", filename: "Icon-400x240.png"),
        AppIconSizeSpec(size: "400x240", scale: "2x", idiom: "tv", filename: "Icon-400x240@2x.png"),
        AppIconSizeSpec(size: "1280x768", scale: "1x", idiom: "tv", filename: "Icon-1280x768.png"),
        AppIconSizeSpec(size: "1280x768", scale: "2x", idiom: "tv", filename: "Icon-1280x768@2x.png")
    ]
}

// MARK: - 扩展

extension ExportFormat {
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .svg: return "svg"
        case .pdf: return "pdf"
        case .icns: return "icns"
        case .ico: return "ico"
        }
    }
    
    var utType: UTType {
        switch self {
        case .png: return .png
        case .svg: return .svg
        case .pdf: return .pdf
        case .icns: return UTType("com.apple.icns")!
        case .ico: return UTType("com.microsoft.ico")!
        }
    }
}

extension ExportService {
    // macOS .iconset 文件名规则
    fileprivate static func macOSIconsetFilename(for spec: AppIconSizeSpec) -> String {
        // 从如 "16x16" 提取整数尺寸
        let comps = spec.size.split(separator: "x")
        let w = comps.first.flatMap { Double($0) } ?? 16
        let h = comps.dropFirst().first.flatMap { Double($0) } ?? w
        let base = "icon_\(Int(w))x\(Int(h))"
        let scaleSuffix = spec.scale == "2x" ? "@2x" : ""
        return "\(base)\(scaleSuffix).png"
    }
}

extension ExportService {
    /// 清洗文件名，移除文件系统不支持的字符，并限制长度
    static func sanitizeFileName(_ name: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_. @()[]{}")
        var result = String()
        for scalar in name.unicodeScalars {
            if allowed.contains(scalar) {
                result.unicodeScalars.append(scalar)
            } else {
                result.append("_")
            }
        }
        // 合并连续下划线
        result = result.replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
        // 去除首尾的空格/点/下划线
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: " ._"))
        if result.isEmpty { result = "icon" }
        if result.count > 64 { result = String(result.prefix(64)) }
        return result
    }
}

extension ExportService {
    /// 将 SwiftUI.Color 转换为 NSColor
    fileprivate static func nsColor(from color: Color) -> NSColor? {
        // 使用更安全的方法从 SwiftUI.Color 创建 NSColor
        let nsColor = NSColor(color)
        // 确保颜色在 RGB 颜色空间中，以防止后续操作中的颜色空间问题
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            // 如果转换失败，尝试使用 cgColor
            if let cg = color.cgColor {
                let fallbackColor = NSColor(cgColor: cg)
                return fallbackColor.usingColorSpace(.sRGB) ?? fallbackColor
            }
            return nil
        }
        return rgbColor
    }
}

extension ExportService {
    /// 导出为 .icns（通过 iconutil 将 .iconset 转换为 .icns）
    func exportAsICNS(
        _ icon: GeneratedIcon,
        to directoryURL: URL,
        compressionQuality: Double? = nil,
        backgroundColor: Color? = nil,
        addPadding: Bool = false,
        paddingPercentage: Double = 0
    ) async throws {
        // 先生成 .iconset（若已存在将覆盖同名文件）
        try await exportAsAppIconSet(
            icon,
            to: directoryURL,
            platform: .macOS,
            compressionQuality: compressionQuality,
            backgroundColor: backgroundColor,
            addPadding: addPadding,
            paddingPercentage: paddingPercentage
        )

        let baseName = ExportService.sanitizeFileName(icon.prompt.isEmpty ? icon.id.uuidString : icon.prompt)
        let iconsetURL = directoryURL.appendingPathComponent("\(baseName).iconset")
        let icnsURL = directoryURL.appendingPathComponent("\(baseName).icns")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw ExportError.saveFailed
        }

        guard process.terminationStatus == 0 else {
            // 可选：读取错误输出以便调试
            // let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            // let errMsg = String(data: errData, encoding: .utf8) ?? ""
            throw ExportError.saveFailed
        }
    }
}