import SwiftUI

struct FrostGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 26
    var interactive: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    interactive ? .regular.interactive() : .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        }
    }
}

extension View {
    func frostGlass(cornerRadius: CGFloat = 26, interactive: Bool = false) -> some View {
        modifier(FrostGlassModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}
