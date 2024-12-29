//
//  Extensions+UIImage.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 28.12.2024.
//

import Foundation
import UIKit

extension UIImage {
    func compressed(quality: CGFloat = 0.5, maxWidth: CGFloat = 1024) -> Data? {
        let scale = maxWidth / self.size.width
        let newHeight = self.size.height * scale
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        defer { UIGraphicsEndImageContext() }

        self.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        return resizedImage.jpegData(compressionQuality: quality)
    }
}
