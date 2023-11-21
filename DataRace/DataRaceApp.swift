//
//  DataRaceApp.swift
//  DataRace
//
//  Created by Moroz Pavlo on 2023-11-16.
//

import SwiftUI

//Global variable. Set internet speed connection here for simmulation async behavior in code.
let internetSpeed: UInt64 = 10_000_000

@main
struct DataRaceApp: App {
        
    @State var isResetWalletRequested = false
    
    var body: some Scene {
        
        WindowGroup {
            VStack {
                
                Button(action: {
                    isResetWalletRequested.toggle()
                }, label: {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 200, height: 50)
                        .foregroundStyle(.red)
                        .overlay {
                            Text("Reset all Wallets")
                                .foregroundStyle(.white)
                        }
                })
                
                TabView {
                    DataRaceView(isResetWalletRequested: $isResetWalletRequested)
                        .tabItem {
                            Label("DataRace", systemImage: "paperclip")
                        }
                    
                    ActorView(isResetWalletRequested: $isResetWalletRequested)
                        .tabItem {
                            Label("Actor", systemImage: "paperclip.circle")
                        }
                    
                    GlobalActorView(isResetWalletRequested: $isResetWalletRequested)
                        .tabItem {
                            Label("Global Actor", systemImage: "paperclip.badge.ellipsis")
                        }
                }
            }
        }
    }
}
