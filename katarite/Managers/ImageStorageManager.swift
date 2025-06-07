import Foundation
import UIKit

/// Manages local storage of images for stories
final class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager.default
    private let imagesDirectory: URL
    
    private init() {
        // Create images directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        imagesDirectory = documentsPath.appendingPathComponent("StoryImages")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    // MARK: - Public Methods
    
    /// Save multiple images for a story
    /// - Parameters:
    ///   - images: Array of StoryImage objects with base64 data
    ///   - storyId: UUID of the story
    /// - Returns: Array of file paths for saved images
    func saveImages(_ images: [StoryImage], forStory storyId: UUID) async throws -> [String] {
        var savedPaths: [String] = []
        
        for (index, storyImage) in images.enumerated() {
            let fileName = generateFileName(storyId: storyId, imageIndex: index)
            let filePath = imagesDirectory.appendingPathComponent(fileName)
            
            // Convert base64 to Data
            guard let imageData = Data(base64Encoded: storyImage.base64Data) else {
                print("⚠️ ImageStorageManager: Failed to decode base64 for image \(index)")
                continue
            }
            
            // Validate that it's a valid image
            guard UIImage(data: imageData) != nil else {
                print("⚠️ ImageStorageManager: Invalid image data for image \(index)")
                continue
            }
            
            do {
                try imageData.write(to: filePath)
                savedPaths.append(fileName)
                print("✅ ImageStorageManager: Saved image to \(fileName)")
            } catch {
                print("❌ ImageStorageManager: Failed to save image \(index): \(error.localizedDescription)")
                throw ImageStorageError.saveFailed(error)
            }
        }
        
        return savedPaths
    }
    
    /// Save a single image from base64 data
    /// - Parameters:
    ///   - base64Data: Base64 encoded image data
    ///   - storyId: UUID of the story
    ///   - imageIndex: Index of the image (for multiple images per story)
    /// - Returns: File path of saved image
    func saveImage(base64Data: String, forStory storyId: UUID, imageIndex: Int = 0) async throws -> String {
        let fileName = generateFileName(storyId: storyId, imageIndex: imageIndex)
        let filePath = imagesDirectory.appendingPathComponent(fileName)
        
        // Convert base64 to Data
        guard let imageData = Data(base64Encoded: base64Data) else {
            throw ImageStorageError.invalidBase64Data
        }
        
        // Validate that it's a valid image
        guard UIImage(data: imageData) != nil else {
            throw ImageStorageError.invalidImageData
        }
        
        do {
            try imageData.write(to: filePath)
            print("✅ ImageStorageManager: Saved image to \(fileName)")
            return fileName
        } catch {
            print("❌ ImageStorageManager: Failed to save image: \(error.localizedDescription)")
            throw ImageStorageError.saveFailed(error)
        }
    }
    
    /// Load an image from the file system
    /// - Parameter fileName: The file name of the image
    /// - Returns: UIImage if found and valid
    func loadImage(fileName: String) -> UIImage? {
        let filePath = imagesDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            print("⚠️ ImageStorageManager: Image file not found: \(fileName)")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: filePath),
              let image = UIImage(data: imageData) else {
            print("⚠️ ImageStorageManager: Failed to load image: \(fileName)")
            return nil
        }
        
        return image
    }
    
    /// Load multiple images for a story
    /// - Parameter imagePaths: Array of file names
    /// - Returns: Array of UIImages
    func loadImages(imagePaths: [String]) -> [UIImage] {
        return imagePaths.compactMap { loadImage(fileName: $0) }
    }
    
    /// Delete images for a story
    /// - Parameter imagePaths: Array of file names to delete
    func deleteImages(imagePaths: [String]) {
        for imagePath in imagePaths {
            let filePath = imagesDirectory.appendingPathComponent(imagePath)
            
            do {
                try fileManager.removeItem(at: filePath)
                print("✅ ImageStorageManager: Deleted image: \(imagePath)")
            } catch {
                print("⚠️ ImageStorageManager: Failed to delete image \(imagePath): \(error.localizedDescription)")
            }
        }
    }
    
    /// Clean up old images (older than specified days)
    /// - Parameter days: Number of days to keep images
    func cleanupOldImages(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            for file in files {
                if let creationDate = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: file)
                    print("🗑️ ImageStorageManager: Cleaned up old image: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("⚠️ ImageStorageManager: Failed to cleanup old images: \(error.localizedDescription)")
        }
    }
    
    /// Get the total size of stored images
    /// - Returns: Size in bytes
    func getTotalStorageSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey], options: [])
            
            return files.reduce(0) { total, file in
                let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(fileSize)
            }
        } catch {
            print("⚠️ ImageStorageManager: Failed to calculate storage size: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Private Methods
    
    private func generateFileName(storyId: UUID, imageIndex: Int) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "story_\(storyId.uuidString)_image_\(imageIndex)_\(timestamp).jpg"
    }
}

// MARK: - Extended Story Model

/// Extended story data for handling multiple images
struct ExtendedStory {
    let story: Story
    let imagePaths: [String]
    
    var images: [UIImage] {
        return ImageStorageManager.shared.loadImages(imagePaths: imagePaths)
    }
    
    init(story: Story, imagePaths: [String] = []) {
        self.story = story
        self.imagePaths = imagePaths
    }
}

// MARK: - Error Types

enum ImageStorageError: LocalizedError {
    case invalidBase64Data
    case invalidImageData
    case saveFailed(Error)
    case directoryCreationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidBase64Data:
            return "Invalid base64 image data"
        case .invalidImageData:
            return "Invalid image data format"
        case .saveFailed(let error):
            return "Failed to save image: \(error.localizedDescription)"
        case .directoryCreationFailed(let error):
            return "Failed to create images directory: \(error.localizedDescription)"
        }
    }
} 