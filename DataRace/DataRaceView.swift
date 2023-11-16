//
//  DataRaceView.swift
//  SwiftConcurrenncyBootcamp
//
//  Created by Moroz Pavlo on 2023-11-15.
//

import SwiftUI


class BankDataRaceService {
    
    enum WalletError: Error {
        case noWallet
        case cannotFetchWalletBalance
    }
    
    private(set) var wallet: Int?
    
    func addMoneyToWallet(sum: Int) throws -> Int {
        guard var currentWallet = wallet else { throw WalletError.noWallet }
        currentWallet += sum
        wallet = currentWallet
        return currentWallet
    }
    
    func takeMoneyFromWallet(sum: Int) throws -> Int {
        guard var currentWallet = wallet else { throw WalletError.noWallet }
//        if currentWallet - sum < 0 {
//            return currentWallet
//        }
        currentWallet -= sum
        wallet = currentWallet
        return currentWallet
    }
    
    func fetchBalance() async throws -> Int? {
        
        print("DEBUG fetchBalance started")
        try? await Task.sleep(nanoseconds: 500_000_000)
        print("DEBUG fetchBalance finished")
        
        let successfulWalletFetch = Bool.random()
        
        if successfulWalletFetch {
            wallet = 0 //set your balance here after mock fething
            return wallet
        } else {
            throw WalletError.cannotFetchWalletBalance
        }
    }
}


class DataRaceViewViewModel: ObservableObject {
    
    @Published var myBalance: Int?
    
    var bankService = BankDataRaceService()
    
    func addToWallet(sum: Int) async   {
        do {
            let myBalanceAfterAddedMoney = try bankService.addMoneyToWallet(sum: sum)
            print("DEBUG myBalanceAfterAddedMoney: \(myBalanceAfterAddedMoney)")
            await MainActor.run {
                self.myBalance = myBalanceAfterAddedMoney
            }
        } catch {
            print("DEBUG addToWallet: \(error)")
        }
    }
    
    func minusFromWallet(sum: Int) async {
        do {
            let myBalanceAfterMinusMoney = try bankService.takeMoneyFromWallet(sum: sum)
            print("DEBUG myBalanceAfterMinusMoney: \(myBalanceAfterMinusMoney)")
            await MainActor.run {
                self.myBalance = myBalanceAfterMinusMoney
            }
        } catch {
            print("DEBUG minusFromWallet: \(error)")
        }
    }
    
    func fetchBalance() async {
        do {
            let balance = try await bankService.fetchBalance()
            print("DEBUG fetchBalance SUCCSESS, balance: \(String(describing: balance))")
            await MainActor.run {
                myBalance = balance
            }
        } catch {
            print("DEBUG fetchBalance ERROR : \(error)")
        }
    }
}

struct DataRaceView: View {
    
    @StateObject var viewModel = DataRaceViewViewModel()
    
    var body: some View {
        VStack {
            Text("Your balance is: \(viewModel.myBalance != nil ? "\(String(describing: viewModel.myBalance!))" : "No info" )")
            
            Button("Refresh") {
                Task {
                    await viewModel.fetchBalance()
                }
            }
            
            HStack {
                Button("Recive All Payments") {
                    Task {
                        for _ in 0...100 {
                            await viewModel.addToWallet(sum: 100)
                        }
                    }
                    
                    Task {
                        for _ in 0...100 {
                            await viewModel.minusFromWallet(sum: 100)
                        }
                    }
                }
                
                Button("Send 100x Payments") {
                    Task {
                        for _ in 0...100 {
                            await viewModel.minusFromWallet(sum: 100)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchBalance()
            }
        }
    }
}

#Preview {
    DataRaceView()
}
