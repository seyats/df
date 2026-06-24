import SwiftUI

/// Компонент аватарки пользователя / группы
struct AvatarView: View {
    let imageURL: String?
    let name: String
    var size: CGFloat = 44
    var showOnlineDot: Bool = false
    var isOnline: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let url = imageURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    default:
                        placeholder
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholder
            }

            if showOnlineDot {
                Circle()
                    .fill(isOnline ? Color.green : Color.gray)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)

            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.gray)
        }
    }
}

/// Аватарка с синей галочкой верификации
struct VerifiedAvatarView: View {
    let imageURL: String?
    let name: String
    var size: CGFloat = 100

    var body: some View {
        VStack(spacing: 0) {
            AvatarView(imageURL: imageURL, name: name, size: size)
        }
    }
}
