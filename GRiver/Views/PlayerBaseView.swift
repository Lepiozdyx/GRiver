import SwiftUI

struct PlayerBaseView: View {
    @EnvironmentObject var viewModel: BaseViewModel
    let onClose: (() -> Void)?
    
    var body: some View {
        ZStack {
            Image(.frame1)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    resourcesSection
                        .offset(y: -30)
                }
            
            VStack {
                buildingsSection
                
                unitRecruitmentSection
                
                supplyPurchaseSection
            }
//            .padding(.top, 40)
//            .padding(.horizontal)
            .padding()
        }
        .padding()
        .padding(.top, 40)
        .navigationBarHidden(true)
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
    
    private var resourcesSection: some View {
        HStack(spacing: 10) {
            resourceCard1("\(viewModel.playerResources.money)", .coin)
            resourceCard1("\(viewModel.playerResources.units)", .units)
            resourceCard2("\(viewModel.playerResources.ammo)", .ammo)
            resourceCard2("\(viewModel.playerResources.food)", .food)
        }
    }
    
    private func resourceCard1(_ value: String, _ icon: ImageResource) -> some View {
        Image(icon)
            .resizable()
            .frame(width: 60, height: 60)
            .overlay(alignment: .bottom) {
                ZStack {
                    Image(.frame2)
                        .resizable()
                        .frame(width: 60, height: 30)
                    
                    Text(value)
                        .laborFont(14)
                }
                .offset(y: 20)
            }
    }
    
    private func resourceCard2(_ value: String, _ icon: ImageResource) -> some View {
        Image(.box)
            .resizable()
            .frame(width: 60, height: 60)
            .overlay {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15)
            }
            .overlay(alignment: .bottom) {
                ZStack {
                    Image(.frame2)
                        .resizable()
                        .frame(width: 60, height: 30)
                    
                    Text(value)
                        .laborFont(14)
                }
                .offset(y: 20)
            }
    }
    
    private var buildingsSection: some View {
        VStack(spacing: 8) {
            buildingRow(
                title: "Storage",
                level: viewModel.baseManager.storageLevel,
                maxLevel: BuildingType.storage.maxLevel,
                upgradeCost: viewModel.getUpgradeCost(for: .storage),
                canUpgrade: viewModel.canUpgradeStorage,
                upgradeAction: viewModel.upgradeStorage
            )
            
            buildingRow(
                title: "Barracks",
                level: viewModel.baseManager.barracksLevel,
                maxLevel: BuildingType.barracks.maxLevel,
                upgradeCost: viewModel.getUpgradeCost(for: .barracks),
                canUpgrade: viewModel.canUpgradeBarracks,
                upgradeAction: viewModel.upgradeBarracks
            )
        }
    }
    
    private func buildingRow(
        title: String,
        level: Int,
        maxLevel: Int,
        upgradeCost: Resource,
        canUpgrade: Bool,
        upgradeAction: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .laborFont(10)
                
                Text("Level \(level)/\(maxLevel)")
                    .laborFont(10)
            }
            
            Spacer()
            
            if level < maxLevel {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(upgradeCost.money)")
                        .laborFont(12)
                    
                    Button("Upgrade") {
                        upgradeAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(!canUpgrade)
                }
            } else {
                Text("MAX")
                    .laborFont(14)
            }
        }
    }
    
    private var unitRecruitmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit")
                .laborFont(14)
            
            HStack(spacing: 6) {
                Button("-") {
                    if viewModel.unitsToBuy > 1 {
                        viewModel.setUnitsToBuy(viewModel.unitsToBuy - 1)
                    }
                }
                .disabled(viewModel.unitsToBuy <= 1)
                .controlSize(.mini)
                
                Text("\(viewModel.unitsToBuy)")
                    .frame(width: 30)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(2)
                
                Button("+") {
                    let maxPossible = min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits())
                    if viewModel.unitsToBuy < maxPossible {
                        viewModel.setUnitsToBuy(viewModel.unitsToBuy + 1)
                    }
                }
                .disabled(viewModel.unitsToBuy >= min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits()))
                .controlSize(.mini)
            }
            
            let unitCost = viewModel.getUnitRecruitmentCost()
            Text("Cost: 💰\(unitCost.money) 🍖\(unitCost.food)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Button("Recruit Units") {
                viewModel.recruitUnits()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(!viewModel.canAffordUnits)
        }
    }
    
    private var supplyPurchaseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ammunition")
                .laborFont(14)
            
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Button("-") {
                            if viewModel.ammoToBuy > 0 {
                                viewModel.setAmmoToBuy(viewModel.ammoToBuy - 1)
                            }
                        }
                        .disabled(viewModel.ammoToBuy <= 0)
                        .controlSize(.mini)
                        
                        Text("\(viewModel.ammoToBuy)")
                            .frame(width: 30)
                            .font(.caption)
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(2)
                        
                        Button("+") {
                            if viewModel.ammoToBuy < viewModel.getMaxAffordableAmmo() {
                                viewModel.setAmmoToBuy(viewModel.ammoToBuy + 1)
                            }
                        }
                        .disabled(viewModel.ammoToBuy >= viewModel.getMaxAffordableAmmo())
                        .controlSize(.mini)
                    }
                }
                
                HStack {
                    Text("Provision")
                        .laborFont(14)
                    
                    HStack(spacing: 4) {
                        Button("-") {
                            if viewModel.foodToBuy > 0 {
                                viewModel.setFoodToBuy(viewModel.foodToBuy - 1)
                            }
                        }
                        .disabled(viewModel.foodToBuy <= 0)
                        .controlSize(.mini)
                        
                        Text("\(viewModel.foodToBuy)")
                            .frame(width: 30)
                            .font(.caption)
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(2)
                        
                        Button("+") {
                            if viewModel.foodToBuy < viewModel.getMaxAffordableFood() {
                                viewModel.setFoodToBuy(viewModel.foodToBuy + 1)
                            }
                        }
                        .disabled(viewModel.foodToBuy >= viewModel.getMaxAffordableFood())
                        .controlSize(.mini)
                    }
                }
            }
            
            let supplyCost = viewModel.getSupplyCost()
            if supplyCost.money > 0 {
                Text("Total: 💰\(supplyCost.money)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button("Purchase Supplies") {
                viewModel.purchaseSupplies()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(!viewModel.canAffordSupplies || (viewModel.ammoToBuy == 0 && viewModel.foodToBuy == 0))
        }
    }
}

// MARK: - Preview
#Preview {
    PlayerBaseView(onClose: { })
        .environmentObject(BaseViewModel())
}
