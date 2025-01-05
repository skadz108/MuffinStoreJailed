//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("MuffinStore Jailed")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("by @mineekdev, UI by @skadz108")
                .font(.caption)
        }
    }
}

struct FooterView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Use at your own risk!")
                    .font(.system(size: 20, weight: .bold))
                
                Text("I am not responsible for any damage, data loss, or any other issues caused by this tool.")
                    .font(.system(size: 14))
                    .opacity(0.75)
            }
        }
        .frame(width: 340)
        .padding(8)
        .background(.red)
        .cornerRadius(14)
    }
}

struct ContentView: View {
    @State var ipaTool: IPATool?
    
    @State var appleId: String = ""
    @State var password: String = ""
    @State var code: String = ""
    
    @State var isAuthenticated: Bool = false
    @State var isDowngrading: Bool = false
    
    @State var appLink: String = ""
    
    var body: some View {
        VStack {
            HeaderView()
                .padding(.top, 5)
            Spacer()
            if !isAuthenticated {
                VStack {
                    List {
                        HStack { // this sucks but it's the only way (i know) that can center this
                            Spacer()
                            VStack(alignment: .center) {
                                Text("Log in to the App Store")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Your credentials will be sent directly to Apple.")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "at")
                            Spacer()
                            TextField("Apple ID", text: $appleId)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "ellipsis.rectangle")
                            Spacer()
                            SecureField("Password", text: $password)
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "lock.shield")
                            Spacer()
                            TextField("2FA Code", text: $code)
                                .keyboardType(.numberPad)
                            Button(action: {
                                showAlert(title: "Instructions", message: "To get a 2FA code, go to Settings > [Your Name] > Sign-In & Security > Two-Factor Authentication > Get Verification Code.")
                            }) {
                                Image(systemName: "questionmark.circle")
                            }
                            .frame(width: 32)
                        }
                        Button(action: {
                            let finalPassword = password + code
                            ipaTool = IPATool(appleId: appleId, password: finalPassword)
                            let ret = ipaTool?.authenticate()
                            isAuthenticated = ret ?? false
                        }) {
                            Text("Authenticate")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .disabled(appleId.isEmpty || password.isEmpty || code.isEmpty)
                    }
                }
            } else {
                if isDowngrading {
                    VStack {
                        VStack {
                            List {
                                Section {
                                    HStack {
                                        Spacer()
                                        VStack(alignment: .center) {
                                            Text("Please wait...")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                            Text("The app is being downgraded. This may take a while.")
                                                .font(.caption)
                                            
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .frame(width: 34, alignment: .center)
                                        }
                                        Spacer()
                                    }
                                }
                                
                                Section {
                                    HStack(spacing: 5) {
                                        Image(systemName: "xmark.app")
                                        Button("Done (exit app)") {
                                            UIApplication.shared.returnToHomeScreen() // scuffed
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        List {
                            Section {
                                HStack {
                                    Spacer()
                                    VStack(alignment: .center) {
                                        Text("Downgrade an app")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("Enter an App Store link.")
                                            .font(.caption)
                                    }
                                    Spacer()
                                }
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.up.forward.app")
                                    Spacer()
                                    TextField("App Link", text: $appLink)
                                }
                                Button(action: {
                                    if appLink.isEmpty {
                                        return
                                    }
                                    var appLinkParsed = appLink.components(separatedBy: "id").last ?? ""
                                    for char in appLinkParsed {
                                        if !char.isNumber {
                                            appLinkParsed = String(appLinkParsed.prefix(upTo: appLinkParsed.firstIndex(of: char)!))
                                            break
                                        }
                                    }
                                    print("App ID: \(appLinkParsed)")
                                    isDowngrading = true
                                    downgradeApp(appId: appLinkParsed, ipaTool: ipaTool!)
                                }) {
                                    Text("Downgrade")
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .disabled(appLink.isEmpty)
                            }
                            
                            Section {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.crop.circle")
                                    Text("Signed in as \(ipaTool?.appleId.redactEmail() ?? "<unknown>")")
                                }
                                HStack(spacing: 5) {
                                    Image(systemName: "person.crop.circle.badge.xmark")
                                    Button(action: {
                                        EncryptedKeychainWrapper.nuke()
                                        EncryptedKeychainWrapper.generateAndStoreKey()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            isAuthenticated = false
                                            UIApplication.shared.returnToHomeScreen()
                                        }
                                    }) {
                                        Text("Log out and exit")
                                    }
                                }
                            }
                            
//                            Button("Log out and exit") {
//                                isAuthenticated = false
//                                EncryptedKeychainWrapper.nuke()
//                                EncryptedKeychainWrapper.generateAndStoreKey()
//                                sleep(3)
//                                UIApplication.shared.returnToHomeScreen() // scuffed
//                            }
//                            .padding()
                        }
                    }
                }
            }
            FooterView()
                .padding()
        }
        .onAppear {
            isAuthenticated = EncryptedKeychainWrapper.hasAuthInfo()
            print("Found \(isAuthenticated ? "auth" : "no auth") info in keychain")
            if isAuthenticated {
                guard let authInfo = EncryptedKeychainWrapper.getAuthInfo() else {
                    print("Failed to get auth info from keychain, logging out")
                    isAuthenticated = false
                    EncryptedKeychainWrapper.nuke()
                    EncryptedKeychainWrapper.generateAndStoreKey()
                    return
                }
                appleId = authInfo["appleId"]! as! String
                password = authInfo["password"]! as! String
                ipaTool = IPATool(appleId: appleId, password: password)
                let ret = ipaTool?.authenticate()
                print("Re-authenticated \(ret! ? "successfully" : "unsuccessfully")")
            } else {
                print("No auth info found in keychain, setting up by generating a key in SEP")
                EncryptedKeychainWrapper.generateAndStoreKey()
            }
        }
    }
}

#Preview {
    ContentView()
}
