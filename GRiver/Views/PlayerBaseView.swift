import SwiftUI

struct PlayerBaseView: View {
    @EnvironmentObject var viewModel: BaseViewModel
    let isOverlay: Bool
    let onClose: (() -> Void)?
    
    init(isOverlay: Bool = false, onClose: (() -> Void)? = nil) {
        self.isOverlay = isOverlay
        self.onClose = onClose
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                if isOverlay {
                    overlayHeader
                } else {
                    baseHeaderSection
                    navigationHintSection
                }
                
                resourcesSection
                
                buildingsSection
                
                unitRecruitmentSection
                
                supplyPurchaseSection
                
                baseStatusSection
                
                if !isOverlay {
                    navigationSection
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(isOverlay ? "" : "Command Base")
        .navigationBarHidden(isOverlay)
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
    
    private var overlayHeader: some View {
        HStack {
            Text("COMMAND BASE")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let onClose = onClose {
                Button("Close") {
                    onClose()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var baseHeaderSection: some View {
        VStack(spacing: 8) {
            Text("COMMAND BASE")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Resource Management & Operations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Base Level:")
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.baseManager.totalBuildingLevels)")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var navigationHintSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Pro Tip")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Text("You can now manage your base directly from the tactical map using the 'Base' button in the top-right corner during gameplay.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Resources")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                resourceCard("Money", "\(viewModel.playerResources.money)", "💰", .green)
                resourceCard("Ammo", "\(viewModel.playerResources.ammo)", "🔫", .orange)
                resourceCard("Food", "\(viewModel.playerResources.food)", "🍖", .brown)
                resourceCard("Units", "\(viewModel.playerResources.units)", "👤", .blue)
            }
            
            let capacity = viewModel.baseManager.storageCapacity
            Text("Storage: \(viewModel.playerResources.money)/\(capacity.money) money, \(viewModel.playerResources.ammo)/\(capacity.ammo) ammo, \(viewModel.playerResources.food)/\(capacity.food) food")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func resourceCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.caption)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buildings")
                .font(.subheadline)
                .fontWeight(.medium)
            
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
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Level \(level)/\(maxLevel)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if level < maxLevel {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("💰\(upgradeCost.money)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button("Upgrade") {
                        upgradeAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(!canUpgrade)
                }
            } else {
                Text("MAX")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var unitRecruitmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit Recruitment")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Units:")
                
                Spacer()
                
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
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var supplyPurchaseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supplies")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 6) {
                HStack {
                    Text("🔫 Ammo:")
                    
                    Spacer()
                    
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
                    Text("🍖 Food:")
                    
                    Spacer()
                    
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
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var baseStatusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Base Status")
                .font(.subheadline)
                .fontWeight(.medium)
            
            let validation = viewModel.getBaseValidation()
            
            if validation.isValid {
                Text("✅ Base operational")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                ForEach(validation.issues, id: \.self) { issue in
                    Text("⚠️ \(issue)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if !validation.warnings.isEmpty {
                ForEach(validation.warnings, id: \.self) { warning in
                    Text("⚡ \(warning)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var navigationSection: some View {
        VStack(spacing: 12) {
            if let warning = viewModel.leaveBaseWarning {
                Text("⚠️ \(warning)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            } else if viewModel.canLeaveBase {
                Text("✅ Base ready for tactical operations")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Text("Tip: Use the navigation buttons above to return to the tactical map and begin operations.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PlayerBaseView()
            .environmentObject(BaseViewModel())
            .preferredColorScheme(.dark)
    }
}
