import SwiftUI

/// View tải ảnh bất đồng bộ có cache (RAM → đĩa → mạng).
///
/// Hiển thị placeholder khi ảnh chưa tải xong. Ảnh được lưu cache
/// bởi `ImageCache.shared` để tránh tải lại nhiều lần.
struct CachedAsyncImage: View {

    /// URL ảnh cần tải (nil = hiển thị placeholder).
    let url: URL?

    /// Ảnh đã tải (giữ state để hiển thị khi có).
    @State private var image: UIImage?

    /// Khởi tạo view.
    init(url: URL?) {
        self.url = url
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder: nền xám + biểu tượng nốt nhạc.
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "music.note")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color(.systemGray))
                }
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            image = await ImageCache.shared.image(for: url)
        }
    }
}

#Preview {
    HStack {
        CachedAsyncImage(url: URL(string: "https://i.ytimg.com/vi/example/hqdefault.jpg"))
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .padding()
}
