import SwiftUI
import Auth0
import LocalAuthentication
import SimpleKeychain
import PasscodeField

struct MainView: View {
    @State private var isLoggedIn = false
    @State private var token: String?
    @State private var idToken: String?
    @State private var showPasscodeCreationView = false
    @State private var showPasscodeEntryView = false

    var body: some View {
        Group {
            if isLoggedIn {
                VStack {
                    ProfileView(idToken: idToken!, token: token!, logout: self.logout)
                    Button("Logout", action: self.logout)
                }
            } else {
                if showPasscodeCreationView {
                    PasscodeCreationView { passcode in
                        self.savePasscode(passcode)
                        self.showPasscodeCreationView = false
                        self.login()
                    }
                } else if showPasscodeEntryView {
                    PasscodeEntryView { passcode in
                        self.authenticateAfterPasscodeCheck(passcode)
                        self.showPasscodeEntryView = false
                    }
                } else {
                    VStack {
                        HeroView()
                        Button("Login", action: self.login)
                    }
                }
            }
        }
        .onAppear(perform: self.checkBiometricAuth)
    }

    func checkBiometricAuth() {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        if credentialsManager.hasValid()
        {
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return
            }
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to retrieve token") { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.retrieveTokenFromKeychain()
                    } else {
                        self.isLoggedIn = false
                    }
                }
            }
        }
    }

    func login() {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        let keychain = SimpleKeychain(service: "Auth0")
        var hasPasscode: Bool = false
        Auth0
            .webAuth()
            .start { result in
                switch result {
                case .success(let credentials):
                    let didStore = credentialsManager.store(credentials: credentials)
                    DispatchQueue.main.async {
                        self.idToken = credentials.idToken
                        self.token = credentials.accessToken
                        hasPasscode = try! keychain.hasItem(forKey: "Passcode")
                        if hasPasscode {
                            self.showPasscodeEntryView = true
                        } else {
                            self.showPasscodeCreationView = true
                        }
                    }
                case .failure(let error):
                    print("Failed with: \(error)")
                }
            }
    }
    
    // this function is not used as the logout button is hidden
    func logout() {
        
        Auth0
            .webAuth()
            .clearSession { result in
                switch result {
                case .success:
                    print("Session cookie cleared")
                    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
                    let keychain = SimpleKeychain(service: "Auth0")
                    let didClear = credentialsManager.clear()
                    try? keychain.deleteAll()
                    

                    DispatchQueue.main.async {
                        self.isLoggedIn = false
                        self.showPasscodeCreationView = false
                        self.showPasscodeEntryView = false
                    }
                    // Delete credentials
                case .failure(let error):
                    print("Failed with: \(error)")
                }
            }
        
    }

    func retrieveTokenFromKeychain() {
        let keychain = SimpleKeychain(service: "Auth0")

        if let passcode = try? keychain.string(forKey: "Passcode") {
            showPasscodeCreationView = false
            showPasscodeEntryView = true
        } else {
            showPasscodeCreationView = true
        }
    }

    func savePasscode(_ passcode: String) {
        let keychain = SimpleKeychain(service: "Auth0")

        try? keychain.set(passcode, forKey: "Passcode")
    }

    func authenticateAfterPasscodeCheck(_ passcode: String) {

                let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
                credentialsManager.credentials { result in
                    switch result {
                    case .success(let credentials):
                        self.token = credentials.accessToken
                        self.idToken = credentials.idToken
                        self.isLoggedIn = true
                    case .failure(let error):
                        print(error)
                        self.isLoggedIn = false
                        // Handle error, present login page
                    }
                }

    }
}

struct PasscodeCreationView: View {
    @State private var passcode = ""
    @State private var reEnterPasscode = ""
    let completion: (String) -> Void

    var body: some View {
        VStack {
            Text("Create a PIN to protect your access!")
                .font(.title3)
                .foregroundColor(.blue)
            
            PasscodeField("Enter PIN") { digits,action  in
                self.passcode = digits.concat
            }   .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            PasscodeField("Re-Enter PIN") { digits,action  in
                self.reEnterPasscode = digits.concat
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            Button(action: savePIN) {
                Text("Create PIN")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(passcode.isEmpty || reEnterPasscode.isEmpty || passcode != reEnterPasscode ? Color.secondary : Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .buttonStyle(PlainButtonStyle())
            .disabled(passcode.isEmpty || reEnterPasscode.isEmpty || passcode != reEnterPasscode)
        }
        .padding()
    }

    func savePIN() {
        if(passcode == reEnterPasscode) {
            completion(passcode)
        }
    }
}

struct PasscodeEntryView: View {
    @State private var passcode = ""
    @State private var showError = false
    @State private var digits: String = ""

    let completion: (String) -> Void

    var body: some View {
        VStack {
            Text("Enter PIN to continue logging in!")
                .font(.title2)

            PasscodeField("") { digits, action in
                let keychain = SimpleKeychain(service: "Auth0")
                
                
                if let storedPasscode = try? keychain.string(forKey: "Passcode") {
                    if digits.concat == storedPasscode {
                        completion(passcode)
                        
                    } else {
                        showError = true
                        action(false)
                        
                    }
                } else {
                    
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            


            if showError {
                Text("Invalid PIN")
                    .foregroundColor(.red)
                    .font(.title3)
                    .padding(.top)
                
            }
        }
        .padding()
    }


}





