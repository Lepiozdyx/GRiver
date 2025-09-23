import SwiftUI

// MARK: - Action Overlay View
struct ActionOverlayView: View {
    @ObservedObject var viewModel: ActionOverlayViewModel
    
    let poi: PointOfInterest
    
    let onCancel: () -> Void
    let onActionRequested: (ActionType, PointOfInterest) -> Void  // изменено
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            overlayContent
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
        viewModel.setOperationCallback { actionType, poi in
            onActionRequested(actionType, poi)
        }
    }
    
    // MARK: - Overlay Content
    private var overlayContent: some View {
        VStack(spacing: 16) {
            
//            poiInfoHeader
            
            if viewModel.isAnalyzing {
                ProgressView("Analyzing operations...")
                    .padding()
            } else if !viewModel.hasValidGameState {
                errorSection
            } else {
                actionsSection
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
        .background(
            Image(.frame1)
                .resizable()
                .shadow(radius: 8)
                .overlay(alignment: .topTrailing) {
                    Button {
                        viewModel.reset()
                        onCancel()
                    } label: {
                        Image(.circleButton)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                    }
                }
        )
        .frame(maxWidth: 300)
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
//    private var poiInfoHeader: some View {
//        VStack(spacing: 4) {
//            HStack {
//                Text(poi.type.displayName)
//                    .laborFont(12)
//                
//                Spacer()
//                
//                Text(poi.status.displayName)
//                    .laborFont(12, color: poiStatusColor)
//            }
//            
//            VStack(alignment: .leading, spacing: 2) {
//                HStack {
//                    Text("Defense:")
//                        .laborFont(10)
//                    
//                    Spacer()
//                    
//                    Text("\(poi.totalDefense)")
//                        .laborFont(10)
//                }
//                
//                HStack {
//                    Text("Units:")
//                        .laborFont(10)
//                    
//                    Spacer()
//                    
//                    Text("\(poi.currentUnits)")
//                        .laborFont(10)
//                }
//                
//                if poi.defenseBonus > 0 {
//                    HStack {
//                        Text("Alert Bonus:")
//                            .laborFont(8)
//                        
//                        Spacer()
//                        
//                        Text("+\(poi.defenseBonus)")
//                            .laborFont(8)
//                    }
//                }
//            }
//        }
//        .padding(.horizontal, 6)
//        .padding(.vertical, 4)
//        .background(Color.gray.opacity(0.1))
//        .cornerRadius(8)
//    }
//    
//    private var poiStatusColor: Color {
//        switch poi.status {
//        case .active: return .green
//        case .captured: return .white
//        case .destroyed: return .red
//        }
//    }
    
    // MARK: - Error Section
    private var errorSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18))
                .foregroundColor(.orange)
            
            Text("Unable to perform operations")
                .laborFont(8)
            
            if let error = viewModel.gameStateError {
                Text(error)
                    .laborFont(8)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 10) {
            Text("Available Operations")
                .laborFont(10)
            
            VStack(spacing: 4) {
                ForEach(ActionType.allCases, id: \.rawValue) { actionType in
                    actionButton(for: actionType)
                }
            }
            
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
            HStack(spacing: 4) {
                Text(actionType.displayName)
                    .laborFont(12)
                
                let percentage = viewModel.getSuccessPercentage(for: actionType)
                
                Text("\(percentage)%")
                    .laborFont(10, color: successProbabilityColor(percentage))
            }
            .frame(height: 50)
            .frame(width: 150)
            .background(
                Image(.rectangleButton)
                    .resizable()
            )
        }
        .disabled(!viewModel.canPerformAction(actionType))
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
    
    // MARK: - Resource Summary Section
    private var resourceSummarySection: some View {
        HStack {
            Text("Current Resources:")
                .laborFont(10)
            
            Spacer()
            
            HStack(spacing: 12) {
                resourceIndicator(.coin, viewModel.playerResources.money)
                resourceIndicator(.ammo, viewModel.playerResources.ammo)
                resourceIndicator(.food, viewModel.playerResources.food)
                resourceIndicator(.units, viewModel.playerResources.units)
            }
        }

    }
    
    private func resourceIndicator(_ icon: ImageResource, _ amount: Int) -> some View {
        HStack(spacing: 2) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 10)
            
            Text("\(amount)")
                .laborFont(8)
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
                    onCancel: {
                        coordinator.hideActionOverlay()
                    },
                    onActionRequested: { actionType, poi in
                        coordinator.executeOperation(actionType: actionType, targetPOI: poi)
                    }
                )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ActionOverlayView(
            viewModel: ActionOverlayViewModel(),
            poi: PointOfInterest(type: .base, position: CGPoint(x: 100, y: 100)),
            onCancel: {},
            onActionRequested: { _, _ in }
        )
    }
}
