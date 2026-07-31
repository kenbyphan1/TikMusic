import SwiftUI

/// Màn hình quản lý API Key.
///
/// Cho phép nhập, lưu (vào Keychain) hoặc xoá API Key runtime.
struct APIKeyView: View {

    /// ViewModel cài đặt.
    @Bindable var viewModel: SettingsViewModel

    /// Ô nhập key.
    @State private var keyInput = ""

    /// Có hiển thị key hay ẩn (secure).
    @State private var isRevealed = false

    var body: some View {
        Form {
            Section {
                if isRevealed {
                    TextField("Nhập API Key", text: $keyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("Nhập API Key", text: $keyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Nhập YouTube Data API Key")
            } footer: {
                Text("Key được lưu an toàn trong Keychain của iOS, không xuất hiện trong mã nguồn. Lấy key tại console.cloud.google.com.")
            }

            Section {
                Button {
                    let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.saveRuntimeKey(trimmed)
                    keyInput = ""
                } label: {
                    Text("Lưu API Key")
                        .font(AppTheme.headlineFont)
                        .frame(maxWidth: .infinity)
                }
                .disabled(trimmedInput.isEmpty)
                .opacity(trimmedInput.isEmpty ? 0.5 : 1)
            }

            if viewModel.hasRuntimeKey {
                Section {
                    Button("Xoá API Key đã lưu", role: .destructive) {
                        viewModel.resetRuntimeKey()
                        keyInput = ""
                    }
                }
            }
        }
        .navigationTitle("API Key")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { isRevealed.toggle() }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                }
                .accessibilityLabel(isRevealed ? "Ẩn API Key" : "Hiện API Key")
            }
        }
    }

    /// Chuỗi nhập sau khi bỏ khoảng trắng.
    private var trimmedInput: String {
        keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    NavigationStack {
        APIKeyView(viewModel: SettingsViewModel(
            colorSchemeManager: ColorSchemeManager(),
            apiKeyProvider: APIKeyProvider()
        ))
    }
}
