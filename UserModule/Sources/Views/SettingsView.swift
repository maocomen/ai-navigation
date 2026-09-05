import SwiftUI
import AppBase

/// 账号设置视图
public struct SettingsView: View {
    @Environment(\.navigator) private var navigator
    private let repository = UserRepository.shared
    @State private var nickname = ""
    @State private var bio = ""
    @State private var showSaved = false

    public init() {}

    public var body: some View {
        List {
            Section("个人资料") {
                TextField("昵称", text: $nickname)
                TextField("个性签名", text: $bio, axis: .vertical)
            }

            Section {
                Button {
                    repository.updateProfile(nickname: nickname, bio: bio)
                    showSaved = true
                } label: {
                    Text("保存设置")
                        .frame(maxWidth: .infinity)
                }
            }

            Section("账号") {
                Button("修改密码", role: .none) {}
                Button("绑定手机号", role: .none) {}
            }

            Section {
                Button("删除账号", role: .destructive) {}
            }
        }
        .navigationTitle("账号设置")
        .onAppear {
            if nickname.isEmpty {
                nickname = repository.currentUser?.nickname ?? ""
                bio = repository.currentUser?.bio ?? ""
            }
        }
        .alert("已保存", isPresented: $showSaved) {
            Button("好", role: .cancel) {}
        }
    }
}
