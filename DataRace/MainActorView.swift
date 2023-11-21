//
//  MainActorView.swift
//  SwiftConcurrenncyBootcamp
//
//  Created by Moroz Pavlo on 2023-11-15.
//

import SwiftUI



actor BankActorService {
    
    enum WalletError: Error {
        case noWallet
        case cannotFetchWalletBalance
    }
    
    @AppStorage("classActorWallet") private(set) var wallet: Int?
    
    func addMoneyToWallet(sum: Int) async throws -> Int {
        
        try? await Task.sleep(nanoseconds: internetSpeed)
        
        guard var currentWallet = wallet else { throw WalletError.noWallet }
        
        currentWallet += sum
        print("============================================")
        print("DEBUG wallet was: \(String(describing: wallet))")
        wallet = currentWallet
        print("DEBUG currentWallet after add money: \(currentWallet)")
        print(print("DEBUG Thread.current: \(Thread.current)"))
        
        return currentWallet
    }
    
    
    func fetchBalance() async throws -> Int? {
        
        print("DEBUG fetchBalance started")
        try? await Task.sleep(nanoseconds: internetSpeed)
        print("DEBUG fetchBalance finished")
        
        let successfulWalletFetch = Bool.random()
        
        if successfulWalletFetch {
            if let walletValue = wallet {
                return walletValue
            } else {
                wallet = 0 //set your balance here after mock fething
                return wallet
            }
        } else {
            throw WalletError.cannotFetchWalletBalance
        }
    }
    
    func resetWallet() async {
        wallet = 0
        let _ = try? await fetchBalance()
    }
}

class ActorViewModel: ObservableObject {
    
    @Published var myBalance: Int?
    @Published var transactionCount = 0
    @Published var isLoadind = false
    
    var bankService = BankActorService()
    
    @MainActor
    func addToWallet(sum: Int) async   {
        do {
            let myBalanceAfterAddedMoney = try await bankService.addMoneyToWallet(sum: sum)
            print("DEBUG myBalanceAfterAddedMoney: \(myBalanceAfterAddedMoney)")
            self.transactionCount += 1
            self.myBalance = myBalanceAfterAddedMoney
        } catch {
            print("DEBUG addToWallet: \(error)")
        }
    }
    
    @MainActor // We can mark func/class like @MainActor and all code in func will be run in main Thread. In can be useful for some cases. But be careful with closures!!
    func fetchBalance() async {
        isLoadind = true
        do {
            let balance = try await bankService.fetchBalance()
            print("DEBUG fetchBalance SUCCSESS, balance: \(String(describing: balance))")
            isLoadind = false
            myBalance = balance
        } catch {
            myBalance = nil
            isLoadind = false
            print("DEBUG fetchBalance ERROR : \(error)")
        }
        
    }
    
    func resetWallet() async {
        await bankService.resetWallet()
        await refresh()
    }
    
    @MainActor
    private func refresh() async {
        self.transactionCount = 0
        
        //All functions and properties that we access should be marked with await if we are interacting with an actor.
        myBalance = await bankService.wallet
    }
}

struct ActorView: View {
    
    @StateObject var viewModel = ActorViewModel()
    @Binding var isResetWalletRequested: Bool
    
    var body: some View {
        VStack(spacing: 50) {
            Text("Total transaction: \(viewModel.transactionCount)")
            
            if !viewModel.isLoadind {
                Text("Your balance is: \(viewModel.myBalance != nil ? "\(String(describing: viewModel.myBalance!)) $" : "No info" )")
                
                Button(action: {
                    Task {
                        await viewModel.fetchBalance()
                    }
                }, label: {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 200, height: 50)
                        .foregroundStyle(.blue)
                        .overlay {
                            Text("Refresh")
                                .foregroundStyle(.white)
                        }
                })
                
                HStack {
                    Button("Recive All Payments") {
                        startPayments()
                    }
                    .disabled(viewModel.myBalance == nil)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchBalance()
            }
        }
        .onChange(of: isResetWalletRequested) {
            Task {
                await viewModel.resetWallet()
            }
        }
    }
    
    private func startPayments() {
        //We call addToWallet in different Task {} for simusating 4 different background Threads.
        Task {
            for _ in 1...100 {
                await viewModel.addToWallet(sum: 10)
            }
        }
        
        Task {
            for _ in 1...100 {
                await viewModel.addToWallet(sum: 10)
            }
        }
        
        Task {
            for _ in 1...100 {
                await viewModel.addToWallet(sum: 10)
            }
        }
        
        Task {
            for _ in 1...100 {
                await viewModel.addToWallet(sum: 10)
            }
        }
    }
}

#Preview {
    ActorView(isResetWalletRequested: .constant(false))
}
