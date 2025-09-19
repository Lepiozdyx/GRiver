import SwiftUI
import SpriteKit

// MARK: - Game Map View
struct GameMapView: View {
    @EnvironmentObject var viewModel: GameSceneViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            // SpriteKit Scene
            SpriteView(scene: viewModel.createScene())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .onReceive(NotificationCenter.default.publisher(for: .poiSelected)) { notification in
                    if let userInfo = notification.userInfo,
                       let poi = userInfo["poi"] as? PointOfInterest,
                       let position = userInfo["position"] as? CGPoint {
                        handlePOISelected(poi, at: position)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .poiDeselected)) { _ in
                    handlePOIDeselected()
                }
            
            // HUD Overlay
            VStack {
                // Top HUD
                HStack(alignment: .top) {
                    // Map statistics
                    mapStatsOverlay
                    
                    Spacer()
                    
                    // Control buttons
                    mapControlButtons
                }
                .padding()
                
                Spacer()
                
                // Bottom instructions or selected POI info
                bottomOverlay
            }
            
            // Base Management Overlay
            if coordinator.showBaseOverlay {
                baseManagementOverlay
                    .zIndex(20)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            viewModel.refreshMap()
        }
    }
    
    // MARK: - Map Stats Overlay
    private var mapStatsOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MAP STATUS")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.mapStatistics)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    // MARK: - Map Control Buttons
    private var mapControlButtons: some View {
        VStack(spacing: 8) {
            Button("Base") {
                coordinator.showBaseManagement()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .foregroundColor(.white)
            
            Button("Reset View") {
                viewModel.resetCamera()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.white)
            
            Button("Refresh") {
                viewModel.refreshMap()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Bottom Overlay
    private var bottomOverlay: some View {
        Group {
            if let selectedPOI = viewModel.selectedPOI {
                selectedPOIInfo(selectedPOI)
                    .padding(.bottom, 20)
            } else {
                mapInstructions
                    .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Selected POI Info
    private func selectedPOIInfo(_ poi: PointOfInterest) -> some View {
        VStack(spacing: 8) {
            // POI Details
            VStack(spacing: 4) {
                Text(poi.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Status: \(poi.status.displayName)")
                    .font(.caption)
                    .foregroundColor(poi.isOperational ? .green : .red)
                
                Text("Defense: \(poi.totalDefense) | Units: \(poi.currentUnits)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if poi.defenseBonus > 0 {
                    Text("Alert Bonus: +\(poi.defenseBonus)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Focus") {
                    viewModel.focusOnPOI(poi)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                if poi.isOperational {
                    Button("Select") {
                        // This will trigger the action overlay
                        selectPOIForAction(poi)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.green)
                }
                
                Button("Close") {
                    viewModel.deselectPOI()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    // MARK: - Map Instructions
    private var mapInstructions: some View {
        VStack(spacing: 4) {
            Text("TACTICAL MAP")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Tap POI to view details")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text("Pinch to zoom • Drag to pan")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    // MARK: - Base Management Overlay
    private var baseManagementOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    coordinator.hideBaseManagement()
                }
            
            // Base management content
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("COMMAND BASE")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Close") {
                        coordinator.hideBaseManagement()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Base management view
                ScrollView {
                    PlayerBaseOverlayContent()
                        .environmentObject(coordinator.getBaseViewModel())
                        .padding()
                }
                .background(Color(.systemBackground))
                .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            }
            .frame(maxWidth: min(UIScreen.main.bounds.width * 0.9, 500))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - POI Interaction Handlers
    private func handlePOISelected(_ poi: PointOfInterest, at position: CGPoint) {
        viewModel.selectPOI(poi, at: position)
    }
    
    private func handlePOIDeselected() {
        viewModel.deselectPOI()
    }
    
    private func selectPOIForAction(_ poi: PointOfInterest) {
        // Convert POI position to screen coordinates for overlay
        let screenPosition = CGPoint(x: 400, y: 300) // Center of screen for now
        
        // Send notification to parent coordinator to show action overlay
        NotificationCenter.default.post(
            name: .requestActionOverlay,
            object: nil,
            userInfo: [
                "poi": poi,
                "position": screenPosition
            ]
        )
    }
}

// MARK: - Player Base Overlay Content
struct PlayerBaseOverlayContent: View {
    @EnvironmentObject var viewModel: BaseViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            
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
    
    // MARK: - Buildings Section
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
    
    // MARK: - Unit Recruitment Section
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
    
    // MARK: - Supply Purchase Section
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
    
    // MARK: - Base Status Section
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
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let requestActionOverlay = Notification.Name("requestActionOverlay")
}

// MARK: - Preview
#Preview {
    GameMapView()
        .environmentObject(GameSceneViewModel())
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}
