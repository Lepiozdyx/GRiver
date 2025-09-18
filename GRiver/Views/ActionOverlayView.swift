import SwiftUI

// MARK: - Action Overlay View
struct ActionOverlayView: View {
    @StateObject private var viewModel = ActionOverlayViewModel()
    
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
            viewModel.selectPOI(poi)
        }
    }
    
    // MARK: - Overlay Content
    private var overlayContent: some View {
        VStack(spacing: 16) {
            
            // MARK: - POI Info Header
            poiInfoHeader
            
            // MARK: - Actions Section
            if viewModel.isAnalyzing {
                ProgressView("Analyzing...")
                    .padding()
            } else {
                actionsSection
            }
            
            // MARK: - Control Buttons
            controlButtons
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
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
        .alert("Operation Result", isPresented: $viewModel.showResult) {
            Button("OK") {
                viewModel.hideResult()
                if let result = viewModel.executionResult {
                    onActionExecuted(result)
                }
            }
        } message: {
            if let result = viewModel.executionResult {
                Text(result.outcomeMessage)
            }
        }
    }
    
    // MARK: - POI Info Header
    private var poiInfoHeader: some View {
        VStack(spacing: 4) {
            Text(poi.type.displayName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(viewModel.targetInfo)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Status: \(poi.status.displayName)")
                .font(.caption)
                .foregroundColor(poi.isOperational ? .green : .red)
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 8) {
            Text("Available Actions")
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
            
            // Best action recommendation
            if let bestAction = viewModel.getBestAction() {
                Text("Recommended: \(bestAction.displayName)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
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
                Text(actionType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                let percentage = viewModel.getSuccessPercentage(for: actionType)
                Text("\(percentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(backgroundColorForAction(actionType))
            .foregroundColor(textColorForAction(actionType))
            .cornerRadius(6)
        }
        .disabled(!viewModel.canPerformAction(actionType) || viewModel.isExecuting)
    }
    
    private func backgroundColorForAction(_ actionType: ActionType) -> Color {
        let statusColor = viewModel.getActionStatusColor(actionType)
        switch statusColor {
        case .good:
            return .green.opacity(0.2)
        case .caution:
            return .yellow.opacity(0.2)
        case .dangerous:
            return .orange.opacity(0.2)
        case .unavailable:
            return .gray.opacity(0.1)
        }
    }
    
    private func textColorForAction(_ actionType: ActionType) -> Color {
        let statusColor = viewModel.getActionStatusColor(actionType)
        switch statusColor {
        case .good:
            return .green
        case .caution:
            return .orange
        case .dangerous:
            return .red
        case .unavailable:
            return .gray
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
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            // Action costs info
            if let selectedAction = viewModel.selectedAction {
                let cost = viewModel.getActionCost(selectedAction)
                if !cost.isEmpty {
                    VStack(alignment: .trailing) {
                        Text("Cost:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            if cost.ammo > 0 {
                                Text("\(cost.ammo)🔫")
                            }
                            if cost.food > 0 {
                                Text("\(cost.food)🍖")
                            }
                            if cost.units > 0 {
                                Text("\(cost.units)👤")
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Container View for Integration
struct ActionOverlayContainer: View {
    @State private var selectedPOI: PointOfInterest?
    @State private var overlayPosition: CGPoint = .zero
    @State private var showOverlay: Bool = false
    
    let onPOISelected: (PointOfInterest, CGPoint) -> Void
    let onActionExecuted: (OperationResult) -> Void
    
    var body: some View {
        ZStack {
            Color.clear
            
            if showOverlay, let poi = selectedPOI {
                ActionOverlayView(
                    poi: poi,
                    position: overlayPosition,
                    onCancel: {
                        hideOverlay()
                    },
                    onActionExecuted: { result in
                        onActionExecuted(result)
                        hideOverlay()
                    }
                )
            }
        }
    }
    
    func showOverlay(for poi: PointOfInterest, at position: CGPoint) {
        selectedPOI = poi
        overlayPosition = position
        showOverlay = true
    }
    
    func hideOverlay() {
        showOverlay = false
        selectedPOI = nil
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ActionOverlayView(
            poi: PointOfInterest(type: .base, position: CGPoint(x: 100, y: 100)),
            position: CGPoint(x: 200, y: 300),
            onCancel: {},
            onActionExecuted: { _ in }
        )
    }
}
