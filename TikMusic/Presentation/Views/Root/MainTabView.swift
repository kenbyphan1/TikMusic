import SwiftUI

/// Tab chính của ứng dụng.
///
/// Gồm 5 tab: Trang chủ, Tìm kiếm, Playlist, Yêu thích, Cài đặt.
struct MainTabView: View {

    /// Container tiêm phụ thuộc.
    @Bindable var container: DependencyContainer

    var body: some View {
        TabView {
            HomeView(viewModel: container.homeViewModel)
                .tabItem {
                    Label("Trang chủ", systemImage: "house.fill")
                }

            SearchView(viewModel: container.searchViewModel)
                .tabItem {
                    Label("Tìm kiếm", systemImage: "magnifyingglass")
                }

            PlaylistListView(viewModel: container.playlistListViewModel)
                .tabItem {
                    Label("Playlist", systemImage: "music.note.list")
                }

            FavoritesView(viewModel: container.favoritesViewModel)
                .tabItem {
                    Label("Yêu thích", systemImage: "heart.fill")
                }

            SettingsView(viewModel: container.settingsViewModel)
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView(container: DependencyContainer())
        .environment(DependencyContainer())
}
