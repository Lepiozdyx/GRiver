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
            
            HStack(spacing: 100) {
                buildingsSection
                
                supplementsSection
            }
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
    
    // MARK: - Section
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
    
    // MARK: - Buildings Section
    private var buildingsSection: some View {
        VStack(spacing: 12) {
            buildingRow(
                title: "Barracks",
                image: .warehouse,
                type: .units,
                level: viewModel.baseManager.barracksLevel,
                maxLevel: BuildingType.barracks.maxLevel,
                upgradeCost: viewModel.getUpgradeCost(for: .barracks),
                canUpgrade: viewModel.canUpgradeBarracks,
                upgradeAction: viewModel.upgradeBarracks
            )
            
            buildingRow(
                title: "Storage",
                image: .base,
                type: .box,
                level: viewModel.baseManager.storageLevel,
                maxLevel: BuildingType.storage.maxLevel,
                upgradeCost: viewModel.getUpgradeCost(for: .storage),
                canUpgrade: viewModel.canUpgradeStorage,
                upgradeAction: viewModel.upgradeStorage
            )
        }
    }
    
    private func buildingRow(
        title: String,
        image: ImageResource,
        type: ImageResource,
        level: Int,
        maxLevel: Int,
        upgradeCost: Resource,
        canUpgrade: Bool,
        upgradeAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .laborFont(14)
            
            HStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90)
                
                Image(type)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
            
            Text("Level \(level)/\(maxLevel)")
                .laborFont(10)
            
            Button {
                upgradeAction()
            } label: {
                Image(.rectangleButton)
                    .resizable()
                    .frame(width: 100, height: 40)
                    .overlay {
                        if level < maxLevel {
                            HStack(spacing: 2) {
                                Image(.coin)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                
                                Text("\(upgradeCost.money)")
                                    .laborFont(12)
                                
                                Image(.coin)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                        } else {
                            Text("MAX")
                                .laborFont(14)
                        }
                    }
            }
            .disabled(!canUpgrade)
        }
    }
    
    // MARK: - Supplements Section
    private var supplementsSection: some View {
        HStack(spacing: 30) {
            supplementsRow(
                title: "Units",
                image: .units,
                amount: viewModel.unitsToBuy,
                cost: viewModel.getUnitRecruitmentCost(),
                canAfford: viewModel.canAffordUnits,
                maxAmount: min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits()),
                onDecrease: {
                    if viewModel.unitsToBuy > 1 {
                        viewModel.setUnitsToBuy(viewModel.unitsToBuy - 1)
                    }
                },
                onIncrease: {
                    let maxPossible = min(viewModel.getMaxAffordableUnits(), viewModel.getMaxRecruitableUnits())
                    if viewModel.unitsToBuy < maxPossible {
                        viewModel.setUnitsToBuy(viewModel.unitsToBuy + 1)
                    }
                },
                onPurchase: {
                    viewModel.recruitUnits()
                }
            )
            
            supplementsRow(
                title: "Ammo",
                image: .ammo,
                amount: viewModel.ammoToBuy,
                cost: Resource(money: viewModel.ammoToBuy * 5),
                canAfford: viewModel.canAffordSupplies && viewModel.ammoToBuy > 0,
                maxAmount: viewModel.getMaxAffordableAmmo(),
                onDecrease: {
                    if viewModel.ammoToBuy > 0 {
                        viewModel.setAmmoToBuy(viewModel.ammoToBuy - 1)
                    }
                },
                onIncrease: {
                    if viewModel.ammoToBuy < viewModel.getMaxAffordableAmmo() {
                        viewModel.setAmmoToBuy(viewModel.ammoToBuy + 1)
                    }
                },
                onPurchase: {
                    viewModel.purchaseSupplies()
                }
            )
            
            supplementsRow(
                title: "Food",
                image: .food,
                amount: viewModel.foodToBuy,
                cost: Resource(money: viewModel.foodToBuy * 2),
                canAfford: viewModel.canAffordSupplies && viewModel.foodToBuy > 0,
                maxAmount: viewModel.getMaxAffordableFood(),
                onDecrease: {
                    if viewModel.foodToBuy > 0 {
                        viewModel.setFoodToBuy(viewModel.foodToBuy - 1)
                    }
                },
                onIncrease: {
                    if viewModel.foodToBuy < viewModel.getMaxAffordableFood() {
                        viewModel.setFoodToBuy(viewModel.foodToBuy + 1)
                    }
                },
                onPurchase: {
                    viewModel.purchaseSupplies()
                }
            )
        }
    }
    
    private func supplementsRow(
        title: String,
        image: ImageResource,
        amount: Int,
        cost: Resource,
        canAfford: Bool,
        maxAmount: Int,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void,
        onPurchase: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .laborFont(14)
            
            Image(.box)
                .resizable()
                .frame(width: 80, height: 80)
                .overlay {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                }
            
            HStack(spacing: 20) {
                Button {
                    onDecrease()
                } label: {
                    Image(.circleButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .overlay {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
                .disabled(amount <= (title == "Units" ? 1 : 0))
                
                Text("\(amount)")
                    .laborFont(22)
                
                Button {
                    onIncrease()
                } label: {
                    Image(.circleButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
                .disabled(amount >= maxAmount)
            }
            
            Button {
                onPurchase()
            } label: {
                Image(.rectangleButton)
                    .resizable()
                    .frame(width: 120, height: 40)
                    .overlay {
                        HStack(spacing: 2) {
                            Image(.coin)
                                .resizable()
                                .frame(width: 15, height: 15)
                            
                            Text("\(cost.money)")
                                .laborFont(10)
                            
                            Image(.coin)
                                .resizable()
                                .frame(width: 15, height: 15)
                        }
                    }
            }
            .disabled(!canAfford)
        }
    }
}

// MARK: - Preview
#Preview {
    PlayerBaseView(onClose: { })
        .environmentObject(BaseViewModel())
}
