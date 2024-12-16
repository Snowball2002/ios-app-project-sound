import SwiftUI
import AVFoundation
import ParseSwift

// MARK: - ParseSwift Initialization
func initializeParse() {
    ParseSwift.initialize(
        applicationId: "VHTjIH18nwMf3Mtry0RSw7BSyWgm46EXc4G8XldR",
        clientKey: "dbr7G1jLRznp7DaTMJIibAZNlRe5lMzcqijN99d0",
        serverURL: URL(string: "https://parseapi.back4app.com")!
    )
}

// MARK: - Main App
@main
struct SoundExchangeApp: App {
    @State private var isLoggedIn = false
    @State private var showSplashScreen = true
    @State private var user = User()

    init() {
        initializeParse()
    }

    var body: some Scene {
        WindowGroup {
            if showSplashScreen {
                SplashScreenView(showSplashScreen: $showSplashScreen)
            } else if isLoggedIn {
                ContentView(user: $user, isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn, user: $user)
            }
        }
    }
}

// MARK: - User Model
struct User: ParseUser {
    var emailVerified: Bool?
    var authData: [String: [String: String]?]?
    var originalData: Data?
    var objectId: String?
    var username: String?
    var email: String?
    var password: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var name: String?
    var profilePicture: ParseFile?
    var balance: Double?

    init() {}
}

// MARK: - Back4App API Integration
struct Back4AppService {
    static func fetchUser(username: String, completion: @escaping (User?) -> Void) {
        Task {
            do {
                let query = User.query("username" == username)
                let result = try await query.first()
                completion(result)
            } catch {
                print("Error fetching user: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @Binding var showSplashScreen: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("SoundExchange")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                Text("Your ultimate destination for exclusive beats.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                Spacer()
                Button(action: {
                    withAnimation {
                        showSplashScreen = false
                    }
                }) {
                    Text("Get Started")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

// MARK: - LoginView
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: User
    @State private var username = ""
    @State private var password = ""
    @State private var isValidCredentials = true
    @State private var errorMessage = ""
    @State private var showingRegistration = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                    .padding(.bottom)
                TextField("Username", text: $username)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.top)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.top)
                if !isValidCredentials {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top)
                }
                Button(action: {
                    Task {
                        do {
                            // Parse's built-in login method
                            let loggedInUser = try await User.login(username: username, password: password)
                            DispatchQueue.main.async {
                                user = loggedInUser
                                isLoggedIn = true
                            }
                        } catch {
                            DispatchQueue.main.async {
                                isValidCredentials = false
                                errorMessage = "Invalid credentials. Please try again."
                                print("Error logging in: \(error.localizedDescription)")
                            }
                        }
                    }
                }) {
                    Text("Log In")
                        .foregroundColor(.black)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(15)
                        .padding(.horizontal)
                }
                Button(action: { showingRegistration.toggle() }) {
                    Text("Don't have an account? Register")
                        .foregroundColor(.white)
                        .padding(.top)
                }
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingRegistration) {
                RegistrationView(isLoggedIn: $isLoggedIn, user: $user)
            }
        }
    }
}

// MARK: - RegistrationView
struct RegistrationView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: User
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                TextField("Name", text: $name)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Button(action: {
                    Task {
                        do {
                            // Log out any existing user to ensure a clean slate
                            try? await User.logout()
                            
                            // Create a fresh User instance
                            var newUser = User()
                            newUser.username = name
                            newUser.email = email
                            newUser.password = password
                            
                            // Attempt signup
                            try await newUser.signup()
                            
                            // Set the current user to the newly signed-up user
                            user = newUser
                            isLoggedIn = true
                        } catch {
                            // Handle errors gracefully
                            errorMessage = "Registration failed: \(error.localizedDescription)"
                            print("Error signing up: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Register")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}


// MARK: - ContentView
struct ContentView: View {
    @Binding var user: User
    @Binding var isLoggedIn: Bool

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            MarketplaceView()
                .tabItem {
                    Label("Marketplace", systemImage: "music.note.list")
                }
            WalletView(user: $user)
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
            SummaryPageView(user: $user)
                .tabItem {
                    Label("Summary", systemImage: "list.bullet.rectangle")
                }
            ProfileView(user: $user, isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .accentColor(.orange)
    }
}


// MARK: - HomeView
struct HomeView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Welcome to SoundExchange!")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                    .padding(.bottom)
                Text("Explore and buy exclusive beats!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom)
                Button(action: {
                    isAnimating.toggle()
                }) {
                    Text("Check out Featured Beats")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                if isAnimating {
                    FeaturedBeatsView()
                }
                Spacer()
            }
            .padding()
        }
    }
}
// MARK: - Featured Beats
struct FeaturedBeatsView: View {
    @State private var player: AVPlayer?

    var body: some View {
        ScrollView {
            VStack {
                Text("Featured Beats")
                    .font(.title)
                    .foregroundColor(.orange)
                    .bold()
                ForEach(1...5, id: \.self) { beat in
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(.orange)
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading) {
                            Text("Beat \(beat)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Genre: Hip-Hop")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            let url = URL(string: "https://www.soundexchange.com/beat\(beat).mp3")!
                            player = AVPlayer(url: url)
                            player?.play()
                        }) {
                            Text("Play")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - MarketplaceView
struct MarketplaceView: View {
    @State private var searchText = ""
    @State private var cart: [String] = []
    let categories = ["Hip-Hop", "EDM", "Lo-Fi", "Pop", "Chill"]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                TextField("Search...", text: $searchText)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                Picker("Category", selection: $searchText) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                ScrollView {
                    ForEach(["Chill Vibes", "Hip-Hop Flow", "EDM Energy", "Lo-Fi Beats", "Pop Hits"], id: \.self) { title in
                        HStack {
                            Text(title)
                                .foregroundColor(.orange)
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                cart.append(title)
                                print("Added \(title) to cart")
                            }) {
                                Text("Add to Cart")
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - WalletView
struct WalletView: View {
    @Binding var user: User
    @State private var depositAmount = ""
    @State private var withdrawAmount = ""

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Your Wallet")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                    .padding(.bottom)
                Text("Balance: $\(user.balance ?? 0.0, specifier: "%.2f")")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.bottom)
                HStack {
                    TextField("Deposit Amount", text: $depositAmount)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    Button(action: {
                        if let amount = Double(depositAmount) {
                            user.balance = (user.balance ?? 0.0) + amount
                            depositAmount = ""
                        }
                    }) {
                        Text("Deposit")
                            .foregroundColor(.black)
                            .bold()
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(15)
                    }
                }
                .padding()
                HStack {
                    TextField("Withdraw Amount", text: $withdrawAmount)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    Button(action: {
                        if let amount = Double(withdrawAmount), amount <= (user.balance ?? 0.0) {
                            user.balance = (user.balance ?? 0.0) - amount
                            withdrawAmount = ""
                        }
                    }) {
                        Text("Withdraw")
                            .foregroundColor(.black)
                            .bold()
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(15)
                    }
                }
                .padding()
                Spacer()
            }
        }
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @Binding var user: User
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Hello, \(user.username ?? "User")!")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                Spacer()
                Button(action: {
                    Task {
                        do {
                            try await User.logout()
                            isLoggedIn = false
                        } catch {
                            print("Error logging out: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Log Out")
                        .foregroundColor(.black)
                        .bold()
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
        }
    }
}
// MARK: - SummaryPageView
struct SummaryPageView: View {
    @Binding var user: User

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.orange]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Account Summary")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                    .padding(.bottom)
                Text("Name: \(user.name ?? "N/A")")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Email: \(user.email ?? "N/A")")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Balance: $\(user.balance ?? 0.0, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
    }
}

