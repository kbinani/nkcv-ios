import UIKit


@IBDesignable
class ContainerView : UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.subviews.forEach { (subview) in
            subview.frame = CGRect(origin: .zero, size: self.bounds.size)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else {
            return nil
        }
        if hit === self {
            return nil
        } else {
            return hit
        }
    }
}
