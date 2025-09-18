import SwiftUI

// MARK: - Player Base View
struct PlayerBaseView: View {
    @StateObject private var viewModel = BaseViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Resources Section
                    resourcesSection
                    
                    // MARK: - Buildings Section
                    buildingsSection
                    
                    // MARK: - Unit Recruitment Section
                    unitRecruitmentSection
                    
                    // MARK: - Supply Purchase Section
                    supplyPurchaseSection
                    
                    // MARK: - Base Status Section
                    baseStatusSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Player Base")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Exit Base") {
                        dismiss()
                    }
                }
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showUpgradeAlert) {
            Button("OK") {
                viewModel.dismissAlert()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            viewModel.refreshData()
        }
    }
    
    // MARK: - Resources Section
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Resources")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Money: \(viewModel.playerResources.money)")
                    Text("Ammo: \(viewModel.playerResources.ammo)")
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Food: \(viewModel.playerResources.food)")
                    Text("Units: \(viewModel.playerResources.units)")
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Buildings Section
    private var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buildings")
                .font(.headline)
            
            // Storage
            VStack(alignment: .leading, spacing: 4) {
                Text("Storage (Level \(viewModel.baseManager.storageLevel))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let storageCost = viewModel.getUpgradeCost(for: .storage)
                Text("Upgrade cost: \(storageCost.money) money, \(storageCost.ammo) ammo, \(storageCost.food) food")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Upgrade Storage") {
                    viewModel.upgradeStorage()
                }
                .disabled(!viewModel.canUpgradeStorage)
            }
            
            Divider()
            
            // Barracks
            VStack(alignment: .leading, spacing: 4) {
                Text("Barracks (Level \(viewModel.baseManager.barracksLevel))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let barracksCost = viewModel.getUpgradeCost(for: .barracks)
                Text("Upgrade cost: \(barracksCost.money) money, \(barracksCost.ammo) ammo, \(barracksCost.food) food")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Upgrade Barracks") {
                    viewModel.upgradeBarracks()
                }
                .disabled(!viewModel.canUpgradeBarracks)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Unit Recruitment Section
    private var unitRecruitmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unit Recruitment")
                .font(.headline)
            
            HStack {
                Text("Units to recruit:")
                
                Spacer()
                
                HStack {
                    Button("-") {
                        if viewModel.unitsToBuy > 1 {
                            viewModel.setUnitsToBuy(viewModel.unitsToBuy - 1)
                        }
                    }
                    .disabled(viewModel.unitsToBuy <= 1)
                    
                    Text("\(viewModel.unitsToBuy)")
                        .frame(width: 40)
                    
                    Button("+") {
                        viewModel.setUnitsToBuy(viewModel.unitsToBuy + 1)
                    }
                    .disabled(viewModel.unitsToBuy >= viewModel.getMaxAffordableUnits())
                }
            }
            
            let unitCost = viewModel.getUnitRecruitmentCost()
            Text("Cost: \(unitCost.money) money, \(unitCost.food) food")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Max possible: \(min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits()))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Recruit Units") {
                    viewModel.recruitUnits()
                }
                .disabled(!viewModel.canAffordUnits)
                
                Spacer()
                
                Button("Max") {
                    viewModel.buyMaxUnits()
                }
                .disabled(viewModel.getMaxRecruitableUnits() == 0)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Supply Purchase Section
    private var supplyPurchaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supply Purchase")
                .font(.headline)
            
            // Ammo
            HStack {
                Text("Ammo:")
                
                Spacer()
                
                HStack {
                    Button("-") {
                        if viewModel.ammoToBuy > 0 {
                            viewModel.setAmmoToBuy(viewModel.ammoToBuy - 1)
                        }
                    }
                    .disabled(viewModel.ammoToBuy <= 0)
                    
                    Text("\(viewModel.ammoToBuy)")
                        .frame(width: 40)
                    
                    Button("+") {
                        viewModel.setAmmoToBuy(viewModel.ammoToBuy + 1)
                    }
                    .disabled(viewModel.ammoToBuy >= viewModel.getMaxAffordableAmmo())
                    
                    Button("Max") {
                        viewModel.buyMaxAmmo()
                    }
                    .controlSize(.small)
                }
            }
            
            // Food
            HStack {
                Text("Food:")
                
                Spacer()
                
                HStack {
                    Button("-") {
                        if viewModel.foodToBuy > 0 {
                            viewModel.setFoodToBuy(viewModel.foodToBuy - 1)
                        }
                    }
                    .disabled(viewModel.foodToBuy <= 0)
                    
                    Text("\(viewModel.foodToBuy)")
                        .frame(width: 40)
                    
                    Button("+") {
                        viewModel.setFoodToBuy(viewModel.foodToBuy + 1)
                    }
                    .disabled(viewModel.foodToBuy >= viewModel.getMaxAffordableFood())
                    
                    Button("Max") {
                        viewModel.buyMaxFood()
                    }
                    .controlSize(.small)
                }
            }
            
            let supplyCost = viewModel.getSupplyCost()
            if supplyCost.money > 0 {
                Text("Total cost: \(supplyCost.money) money")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Purchase Supplies") {
                viewModel.purchaseSupplies()
            }
            .disabled(!viewModel.canAffordSupplies || (viewModel.ammoToBuy == 0 && viewModel.foodToBuy == 0))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Base Status Section
    private var baseStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Base Status")
                .font(.headline)
            
            Text(viewModel.baseStatusSummary)
                .font(.subheadline)
            
            let validation = viewModel.getBaseValidation()
            
            if !validation.issues.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Issues:")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    ForEach(validation.issues, id: \.self) { issue in
                        Text("• \(issue)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if !validation.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Warnings:")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    ForEach(validation.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Readiness check
            if let warning = viewModel.leaveBaseWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            } else if viewModel.canLeaveBase {
                Text("Base ready for operations")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    PlayerBaseView()
        .preferredColorScheme(.dark)
}
