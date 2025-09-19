import SwiftUI

// MARK: - Player Base View
struct PlayerBaseView: View {
    @EnvironmentObject var viewModel: BaseViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - Header Section
                baseHeaderSection
                
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
                
                // MARK: - Navigation Section
                navigationSection
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Player Base")
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
    
    // MARK: - Base Header Section
    private var baseHeaderSection: some View {
        VStack(spacing: 8) {
            Text("COMMAND BASE")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Resource Management & Operations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Base level indicator
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
    
    // MARK: - Resources Section
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Resources")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                resourceCard("Money", "\(viewModel.playerResources.money)", "💰", .green)
                resourceCard("Ammo", "\(viewModel.playerResources.ammo)", "🔫", .orange)
                resourceCard("Food", "\(viewModel.playerResources.food)", "🍖", .brown)
                resourceCard("Units", "\(viewModel.playerResources.units)", "👤", .blue)
            }
            
            // Storage capacity info
            let capacity = viewModel.baseManager.storageCapacity
            Text("Storage: \(viewModel.playerResources.money)/\(capacity.money) money, \(viewModel.playerResources.ammo)/\(capacity.ammo) ammo, \(viewModel.playerResources.food)/\(capacity.food) food")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func resourceCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Buildings Section
    private var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Base Buildings")
                .font(.headline)
            
            // Storage Building
            buildingCard(
                title: "Storage Facility",
                level: viewModel.baseManager.storageLevel,
                maxLevel: BuildingType.storage.maxLevel,
                description: "Increases resource storage capacity",
                upgradeCost: viewModel.getUpgradeCost(for: .storage),
                canUpgrade: viewModel.canUpgradeStorage,
                upgradeAction: viewModel.upgradeStorage
            )
            
            // Barracks Building
            buildingCard(
                title: "Barracks",
                level: viewModel.baseManager.barracksLevel,
                maxLevel: BuildingType.barracks.maxLevel,
                description: "Increases maximum unit capacity",
                upgradeCost: viewModel.getUpgradeCost(for: .barracks),
                canUpgrade: viewModel.canUpgradeBarracks,
                upgradeAction: viewModel.upgradeBarracks
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func buildingCard(
        title: String,
        level: Int,
        maxLevel: Int,
        description: String,
        upgradeCost: Resource,
        canUpgrade: Bool,
        upgradeAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Level \(level)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    if level < maxLevel {
                        Text("/ \(maxLevel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("MAX")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if level < maxLevel {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade Cost:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if upgradeCost.money > 0 {
                            Text("💰\(upgradeCost.money)")
                        }
                        if upgradeCost.ammo > 0 {
                            Text("🔫\(upgradeCost.ammo)")
                        }
                        if upgradeCost.food > 0 {
                            Text("🍖\(upgradeCost.food)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Button("Upgrade") {
                        upgradeAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!canUpgrade)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
    
    // MARK: - Unit Recruitment Section
    private var unitRecruitmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unit Recruitment")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Units to recruit:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button("-") {
                            if viewModel.unitsToBuy > 1 {
                                viewModel.setUnitsToBuy(viewModel.unitsToBuy - 1)
                            }
                        }
                        .disabled(viewModel.unitsToBuy <= 1)
                        
                        Text("\(viewModel.unitsToBuy)")
                            .frame(width: 50)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        Button("+") {
                            let maxPossible = min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits())
                            if viewModel.unitsToBuy < maxPossible {
                                viewModel.setUnitsToBuy(viewModel.unitsToBuy + 1)
                            }
                        }
                        .disabled(viewModel.unitsToBuy >= min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits()))
                    }
                }
                
                let unitCost = viewModel.getUnitRecruitmentCost()
                Text("Cost: 💰\(unitCost.money) 🍖\(unitCost.food) per unit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Available slots: \(viewModel.getMaxRecruitableUnits())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Can afford: \(viewModel.getMaxAffordableUnits())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button("Recruit Units") {
                        viewModel.recruitUnits()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canAffordUnits)
                    
                    Button("Max") {
                        viewModel.buyMaxUnits()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.getMaxRecruitableUnits() == 0 || viewModel.getMaxAffordableUnits() == 0)
                }
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
            
            VStack(spacing: 12) {
                // Ammo Purchase
                supplyPurchaseRow(
                    title: "Ammunition",
                    icon: "🔫",
                    value: $viewModel.ammoToBuy,
                    maxValue: viewModel.getMaxAffordableAmmo(),
                    pricePerUnit: 5,
                    onMaxTap: viewModel.buyMaxAmmo
                )
                
                // Food Purchase
                supplyPurchaseRow(
                    title: "Food Supplies",
                    icon: "🍖",
                    value: $viewModel.foodToBuy,
                    maxValue: viewModel.getMaxAffordableFood(),
                    pricePerUnit: 2,
                    onMaxTap: viewModel.buyMaxFood
                )
                
                // Total cost and purchase button
                let supplyCost = viewModel.getSupplyCost()
                if supplyCost.money > 0 {
                    HStack {
                        Text("Total cost:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("💰\(supplyCost.money)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 4)
                }
                
                Button("Purchase Supplies") {
                    viewModel.purchaseSupplies()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canAffordSupplies || (viewModel.ammoToBuy == 0 && viewModel.foodToBuy == 0))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func supplyPurchaseRow(
        title: String,
        icon: String,
        value: Binding<Int>,
        maxValue: Int,
        pricePerUnit: Int,
        onMaxTap: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(icon) \(title)")
                    .font(.subheadline)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("-") {
                        if value.wrappedValue > 0 {
                            value.wrappedValue -= 1
                        }
                    }
                    .disabled(value.wrappedValue <= 0)
                    
                    Text("\(value.wrappedValue)")
                        .frame(width: 50)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Button("+") {
                        if value.wrappedValue < maxValue {
                            value.wrappedValue += 1
                        }
                    }
                    .disabled(value.wrappedValue >= maxValue)
                    
                    Button("Max") {
                        onMaxTap()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            HStack {
                Text("💰\(pricePerUnit) each")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Max: \(maxValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Base Status Section
    private var baseStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Base Status")
                .font(.headline)
            
            Text(viewModel.baseStatusSummary)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            let validation = viewModel.getBaseValidation()
            
            if !validation.issues.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("⚠️ Issues:")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    
                    ForEach(validation.issues, id: \.self) { issue in
                        Text("• \(issue)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if !validation.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("⚡ Warnings:")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    
                    ForEach(validation.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Navigation Section
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
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    PlayerBaseView()
        .environmentObject(BaseViewModel())
        .preferredColorScheme(.dark)
}
