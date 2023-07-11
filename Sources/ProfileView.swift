import SwiftUI

struct ProfileView: View {
    let idToken: String
    let token: String
    let logout: () -> Void
    @State private var user: User? = nil
    
    var body: some View {
        VStack {
            if user != nil {
                ProfileHeader(picture: user!.picture)
                    .padding()
                
                Text("Welcome, \(user!.name)!")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                Text("Account Balance: $1000")
                    .font(.headline)
                    .padding(.bottom)
                
                Spacer()
                
                Button("Place Bet") {
                    // Perform betting action
                }.buttonStyle(PlainButtonStyle())
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
                .padding(.bottom)
                
                Button("View Betting History") {
                    // Show betting history
                }
                .font(.headline)
                .foregroundColor(.blue)
                
                Spacer()
                
                List {
                          if user != nil {
                              Section(header: Text("Profile")) {
                                  ProfileCell(key: "ID", value: user!.id)
                                  ProfileCell(key: "Name", value: user!.name)
                                  ProfileCell(key: "Email", value: user!.email)
                                  ProfileCell(key: "Email verified?", value: user!.emailVerified)
                                  ProfileCell(key: "Updated at", value: user!.updatedAt)
                              }
                          }
                      }
            }
        }
        .onAppear {
            user = User.init(from: idToken)
        }
    }
}




