import Foundation
import CoreGraphics


extension CGSize {
    func scaleAspectFit(within size: CGSize) -> CGFloat {
        return min(size.width / self.width, size.height / self.height)
    }

    func aspectFit(within size: CGSize) -> CGSize {
        let scale = self.scaleAspectFit(within: size)
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}
