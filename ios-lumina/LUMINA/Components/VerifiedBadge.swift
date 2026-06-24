import SwiftUI

/// Синяя галочка верификации (зубчатая звезда)
struct VerifiedBadge: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            // Зубчатая звезда
            Image(systemName: "seal.fill")
                .font(.system(size: size))
                .foregroundStyle(LuminaColor.verifiedBadge)

            // Белая галочка внутри
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
