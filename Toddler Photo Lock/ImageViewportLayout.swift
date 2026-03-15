import UIKit

enum ImageViewportLayout {
    static func fittedSize(for imageSize: CGSize, in viewport: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, viewport.width > 0, viewport.height > 0 else {
            return .zero
        }

        let scale = min(viewport.width / imageSize.width, viewport.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    static func centeredInsets(contentSize: CGSize, in viewport: CGSize) -> UIEdgeInsets {
        let verticalInset = max(0, (viewport.height - contentSize.height) / 2)
        let horizontalInset = max(0, (viewport.width - contentSize.width) / 2)
        return UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
}
