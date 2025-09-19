import SwiftUI

// MARK: - Action Overlay View
struct ActionOverlayView: View {
    @ObservedObject var viewModel: ActionOverlayViewModel
    
    let poi: PointOfInterest
    let position: CGPoint
    let onCancel: () -> Void
    let onActionExecuted: (OperationResult) -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Main overlay content
            overlayContent
                .position(x: position.x, y: position.y)
        }
        .onAppear {
            setupViewModel()
        }
        .onDisappear {
            viewModel.reset()
        }
    }
    
    // MARK: - Setup
    private func setupViewModel() {
        viewModel.selectPOI(poi)
        viewModel.setOperationCallback { result in
            onActionExecuted(result)
        }
    }
    
    // MARK: - Overlay Content
    private var overlayContent: some View {
        VStack(spacing: 16) {
            
            // MARK: - POI Info Header
            poiInfoHeader
            
            // MARK: - Actions Section
            if viewModel.isAnalyzing {
                ProgressView("Analyzing operations...")
                    .padding()
            } else if !viewModel.hasValidGameState {
                errorSection
            } else {
                actionsSection
            }
            
            // MARK: - Control Buttons
            controlButtons
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .frame(maxWidth: 320)
        .confirmationDialog(
            viewModel.confirmationTitle,
            isPresented: $viewModel.showExecutionConfirm,
            titleVisibility: .visible
        ) {
            Button("Execute", role: .destructive) {
                viewModel.executeSelectedAction()
            }
            Button("Cancel", role: .cancel) {
                viewModel.hideExecutionConfirm()
            }
        } message: {
            Text(viewModel.confirmationMessage)
        }
    }
    
    // MARK: - POI Info Header
    private var poiInfoHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text(poi.type.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(poi.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(poiStatusColor.opacity(0.2))
                    .foregroundColor(poiStatusColor)
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Defense:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(poi.totalDefense)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Units:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(poi.currentUnits)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if poi.defenseBonus > 0 {
                    HStack {
                        Text("Alert Bonus:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("+\(poi.defenseBonus)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var poiStatusColor: Color {
        switch poi.status {
        case .active: return .green
        case .captured: return .blue
        case .destroyed: return .red
        }
    }
    
    // MARK: - Error Section
    private var errorSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Unable to perform operations")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let error = viewModel.gameStateError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Text("Available Operations")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(ActionType.allCases, id: \.rawValue) { actionType in
                    actionButton(for: actionType)
                }
            }
            
            // Strategic recommendations
            if !viewModel.getRecommendedActions().isEmpty {
                recommendationsSection
            }
            
            // Resource summary
            resourceSummarySection
        }
    }
    
    // MARK: - Action Button
    private func actionButton(for actionType: ActionType) -> some View {
        Button(action: {
            if viewModel.canPerformAction(actionType) {
                viewModel.showExecutionConfirm(for: actionType)
            }
        }) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(actionType.icon)
                        .font(.caption)
                    
                    Text(actionType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                let percentage = viewModel.getSuccessPercentage(for: actionType)
                Text("\(percentage)%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(successProbabilityColor(percentage))
                
                // Risk indicator
                let riskColor = riskIndicatorColor(for: actionType)
                Circle()
                    .fill(riskColor)
                    .frame(width: 6, height: 6)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(backgroundColorForAction(actionType))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColorForAction(actionType), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .disabled(!viewModel.canPerformAction(actionType) || viewModel.isExecuting)
    }
    
    private func successProbabilityColor(_ percentage: Int) -> Color {
        if percentage >= 70 {
            return .green
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func riskIndicatorColor(for actionType: ActionType) -> Color {
        let statusColor = viewModel.getActionStatusColor(actionType)
        switch statusColor {
        case .good: return .green
        case .caution: return .yellow
        case .dangerous: return .red
        case .unavailable: return .gray
        }
    }
    
    private func backgroundColorForAction(_ actionType: ActionType) -> Color {
        let statusColor = viewModel.getActionStatusColor(actionType)
        switch statusColor {
        case .good: return .green.opacity(0.1)
        case .caution: return .yellow.opacity(0.1)
        case .dangerous: return .orange.opacity(0.1)
        case .unavailable: return .gray.opacity(0.05)
        }
    }
    
    private func borderColorForAction(_ actionType: ActionType) -> Color {
        let statusColor = viewModel.getActionStatusColor(actionType)
        switch statusColor {
        case .good: return .green.opacity(0.3)
        case .caution: return .yellow.opacity(0.3)
        case .dangerous: return .orange.opacity(0.3)
        case .unavailable: return .gray.opacity(0.2)
        }
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recommended:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            let recommended = viewModel.getRecommendedActions()
            if let best = recommended.first {
                Text(best.displayName)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Resource Summary Section
    private var resourceSummarySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Current Resources:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                resourceIndicator("💰", viewModel.playerResources.money)
                resourceIndicator("🔫", viewModel.playerResources.ammo)
                resourceIndicator("🍖", viewModel.playerResources.food)
                resourceIndicator("👤", viewModel.playerResources.units)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func resourceIndicator(_ icon: String, _ amount: Int) -> some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.caption2)
            Text("\(amount)")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                viewModel.reset()
                onCancel()
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            if viewModel.isExecuting {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Executing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Tap operation to execute")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Coordinator Integration Wrapper
struct ActionOverlayContainer: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        Group {
            if coordinator.showActionOverlay,
               let poi = coordinator.selectedPOI {
                ActionOverlayView(
                    viewModel: coordinator.getActionOverlayViewModel(),
                    poi: poi,
                    position: coordinator.overlayPosition,
                    onCancel: {
                        coordinator.hideActionOverlay()
                    },
                    onActionExecuted: { result in
                        coordinator.handleOperationResult(result)
                    }
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    @StateObject var testViewModel = ActionOverlayViewModel()
    
    return ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ActionOverlayView(
            viewModel: testViewModel,
            poi: PointOfInterest(type: .base, position: CGPoint(x: 100, y: 100)),
            position: CGPoint(x: 200, y: 300),
            onCancel: {},
            onActionExecuted: { _ in }
        )
    }
    .onAppear {
        // Setup test data
        testViewModel.setGameStateManager(GameStateManager())
    }
}
