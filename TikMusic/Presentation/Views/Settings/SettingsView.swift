import SwiftUI

/// Màn hình Cài đặt.
///
/// Gồm: chủ đề giao diện (Dark/Light/System), xoá cache,
/// quản lý API Key, thông tin & chính sách quyền riêng tư.
struct SettingsView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                storageSection
                apiKeySection
                aboutSection
            }
            .navigationTitle("Cài đặt")
        }
    }

    // MARK: - Giao diện

    private var appearanceSection: some View {
        Section("Giao diện") {
            ForEach(ColorSchemeManager.ThemePreference.allCases) { preference in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.themePreference = preference
                    }
                } label: {
                    HStack {
                        Image(systemName: preference.symbolName)
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 28)
                        Text(preference.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        if viewModel.themePreference == preference {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bộ nhớ

    private var storageSection: some View {
        Section("Bộ nhớ") {
            HStack {
                Label("Dung lượng cache", systemImage: "internaldrive")
                Spacer()
                Text(viewModel.cacheSizeText)
                    .foregroundStyle(.secondary)
            }

            Button("Xoá cache", systemImage: "trash") {
                viewModel.clearCache()
            }
            .foregroundStyle(.red)
        } footer: {
            Text("Xoá ảnh đã lưu để giải phóng dung lượng. Ứng dụng sẽ tải lại ảnh khi cần.")
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        Section("API Key") {
            HStack {
                Label("Trạng thái", systemImage: "key.fill")
                Spacer()
                Text(viewModel.isAPIKeyConfigured ? "Đã cấu hình" : "Chưa cấu hình")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(viewModel.isAPIKeyConfigured ? .green : .red)
            }

            NavigationLink {
                APIKeyView(viewModel: viewModel)
            } label: {
                Label("Quản lý API Key", systemImage: "gearshape")
            }

            if viewModel.hasRuntimeKey {
                Button("Xoá API Key đã lưu", systemImage: "xmark.circle", role: .destructive) {
                    viewModel.resetRuntimeKey()
                }
            }
        } footer: {
            Text("API Key được đọc từ Config.xcconfig khi build, hoặc nhập trực tiếp tại đây (lưu trong Keychain). Không bao giờ hardcode trong mã nguồn.")
        }
    }

    // MARK: - Về TikMusic

    private var aboutSection: some View {
        Section("Về TikMusic") {
            LabeledContent("Phiên bản", value: viewModel.appVersion)

            NavigationLink {
                AboutView()
            } label: {
                Label("Giới thiệu", systemImage: "info.circle")
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Chính sách quyền riêng tư", systemImage: "hand.raised.fill")
            }
        }
    }
}

/// Màn hình giới thiệu ứng dụng.
private struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.accentGradient)
                        .frame(width: 96, height: 96)
                    Image(systemName: "music.note")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 32)

                Text("TikMusic")
                    .font(AppTheme.titleFont)

                Text("Tổng hợp video nhạc theo các chủ đề phổ biến trên TikTok, sử dụng YouTube Data API. Tìm kiếm, lưu playlist, yêu thích và phát video mọi lúc mọi nơi.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Ứng dụng này không liên kết với TikTok hoặc YouTube. Nội dung video thuộc về các kênh sở hữu trên YouTube.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Giới thiệu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Màn hình chính sách quyền riêng tư.
private struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(privacyPolicyText)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
            }
            .padding(AppTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Chính sách quyền riêng tư")
        .navigationBarTitleDisplayMode(.inline)
    }

    private let privacyPolicyText = """
    CHÍNH SÁCH QUYỀN RIÊNG TƯ

    1. Dữ liệu thu thập
    - TikMusic không thu thập dữ liệu cá nhân của người dùng.
    - Dữ liệu cục bộ (playlist, yêu thích, lịch sử tìm kiếm) chỉ được lưu trên thiết bị của bạn.

    2. API Key
    - API Key YouTube do chính bạn cung cấp, được lưu an toàn trong Keychain của iOS.
    - Không có dữ liệu nào gửi tới máy chủ của chúng tôi.

    3. Dịch vụ bên thứ ba
    - Ứng dụng sử dụng YouTube Data API và trình phát nhúng YouTube.
    - Việc sử dụng phải tuân thủ Điều khoản dịch vụ của Google/YouTube.

    4. Quyền riêng tư của trẻ em
    - Ứng dụng không hướng tới trẻ em dưới 13 tuổi.

    5. Liên hệ
    - Mọi thắc mắc về chính sách, vui lòng liên hệ qua kênh hỗ trợ của ứng dụng.

    Ngày cập nhật: 2026
    """
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(
        colorSchemeManager: ColorSchemeManager(),
        apiKeyProvider: APIKeyProvider()
    ))
}
