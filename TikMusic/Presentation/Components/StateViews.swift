import SwiftUI

/// View hiển thị khi không có dữ liệu (empty state).
struct EmptyStateView: View {

    /// Biểu tượng hiển thị.
    let symbolName: String

    /// Tiêu đề.
    let title: String

    /// Mô tả chi tiết.
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient.opacity(0.12))
                    .frame(width: 96, height: 96)

                Image(systemName: symbolName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(AppTheme.accentGradient)
            }

            Text(title)
                .font(AppTheme.titleFont)

            Text(message)
                .font(AppTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

/// View hiển thị khi có lỗi.
struct ErrorStateView: View {

    /// Thông điệp lỗi.
    let message: String

    /// Hành động thử lại.
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 96, height: 96)

                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Color.red)
            }

            Text("Đã có lỗi xảy ra")
                .font(AppTheme.titleFont)

            Text(message)
                .font(AppTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Button(action: retryAction) {
                Label("Thử lại", systemImage: "arrow.clockwise")
                    .font(AppTheme.headlineFont)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

#Preview {
    VStack(spacing: 24) {
        EmptyStateView(
            symbolName: "star",
            title: "Chưa có yêu thích",
            message: "Nhấn biểu tượng trái tim trên video để lưu vào danh sách."
        )
        ErrorStateView(message: "Không thể kết nối tới máy chủ.") {}
    }
}
