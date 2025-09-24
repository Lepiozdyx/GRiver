import SwiftUI

// MARK: - Operation Result View
struct OperationResultView: View {
    @StateObject private var viewModel = OperationResultViewModel()
    
    let operationResult: OperationResult
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                
                // MARK: - Result Header
                resultHeaderSection
                
                // MARK: - Operation Summary
                operationSummarySection
                
                // MARK: - Resource Changes
                resourceChangesSection
                
                // MARK: - Game Status
                gameStatusSection
                
                // MARK: - Impact Analysis
                if viewModel.canShowAnalysis {
                    impactAnalysisSection
                }
                
                // MARK: - Strategic Analysis
                if viewModel.showDetailedAnalysis {
                    strategicAnalysisSection
                }
                
                // MARK: - Recommendations
                if viewModel.showRecommendations {
                    recommendationsSection
                }
                
                // MARK: - Action Buttons
                actionButtonsSection
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .onAppear {
            viewModel.processResult(operationResult)
        }
    }
    
    // MARK: - Result Header
    private var resultHeaderSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.resultTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(resultHeaderColor)
            
            Text(operationResult.outcomeMessage)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var resultHeaderColor: Color {
        return operationResult.success ? .green : .red
    }
    
    // MARK: - Operation Summary
    private var operationSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Operation Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Action: \(operationResult.actionType.displayName)")
                Text("Target: \(operationResult.targetPOI.type.displayName)")
                Text("Success Chance: \(operationResult.successPercentage)%")
                Text("Your Strength: \(Int(operationResult.playerStrength))")
                Text("Enemy Strength: \(Int(operationResult.enemyStrength))")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Resource Changes
    private var resourceChangesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resource Changes")
                .font(.headline)
            
            if !operationResult.resourcesLost.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lost:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    resourceChangeDetails(operationResult.resourcesLost, isGain: false)
                }
            }
            
            if !operationResult.resourcesGained.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gained:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    resourceChangeDetails(operationResult.resourcesGained, isGain: true)
                }
            }
            
            if operationResult.netValue != 0 {
                HStack {
                    Text("Net Result:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(operationResult.netValue > 0 ? "+" : "")\(operationResult.netValue)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(operationResult.netValue > 0 ? .green : .red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func resourceChangeDetails(_ resource: Resource, isGain: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if resource.money > 0 {
                resourceRow("Money", resource.money, isGain: isGain)
            }
            if resource.ammo > 0 {
                resourceRow("Ammo", resource.ammo, isGain: isGain)
            }
            if resource.food > 0 {
                resourceRow("Food", resource.food, isGain: isGain)
            }
            if resource.units > 0 {
                resourceRow("Units", resource.units, isGain: isGain)
            }
        }
    }
    
    private func resourceRow(_ name: String, _ amount: Int, isGain: Bool) -> some View {
        HStack {
            Text(name)
                .font(.caption)
            
            Spacer()
            
            Text("\(isGain ? "+" : "-")\(amount)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isGain ? .green : .red)
        }
    }
    
    // MARK: - Game Status
    private var gameStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Status")
                .font(.headline)
            
            Text(viewModel.gameStateSummary)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Impact Analysis
    private var impactAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Impact Analysis")
                    .font(.headline)
                
                Spacer()
                
                Text(viewModel.impactLevel.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(impactLevelColor.opacity(0.2))
                    .foregroundColor(impactLevelColor)
                    .cornerRadius(4)
            }
            
            Text(viewModel.strategicAnalysis)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var impactLevelColor: Color {
        switch viewModel.impactLevel {
        case .minimal: return .gray
        case .moderate: return .blue
        case .significant: return .orange
        case .critical: return .red
        }
    }
    
    // MARK: - Strategic Analysis
    private var strategicAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Assessment")
                .font(.headline)
            
            Text(viewModel.riskAssessment)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Recommendations
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            if viewModel.nextStepRecommendations.isEmpty {
                Text("No specific recommendations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(viewModel.nextStepRecommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            
            // Toggle buttons for detailed views
            HStack(spacing: 12) {
                Button(viewModel.showDetailedAnalysis ? "Hide Analysis" : "Show Analysis") {
                    if viewModel.showDetailedAnalysis {
                        viewModel.hideDetailedView()
                    } else {
                        viewModel.showDetailedView()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canShowAnalysis)
                
                Button(viewModel.showRecommendations ? "Hide Tips" : "Show Tips") {
                    if viewModel.showRecommendations {
                        viewModel.hideRecommendationsView()
                    } else {
                        viewModel.showRecommendationsView()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canShowAnalysis)
            }
            
            // Main continue button
            Button("Continue Mission") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

// MARK: - Standalone Result View for Overlay
struct OperationResultStandaloneView: View {
    @StateObject private var viewModel = OperationResultViewModel()
    
    let operationResult: OperationResult
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onContinue()
                }
            
            overlayContent
        }
        .onAppear {
            viewModel.processResult(operationResult)
        }
    }
    
    private var overlayContent: some View {
        VStack(spacing: 12) {
            resultHeader
            
            operationDetails
            
            if hasResourceChanges {
                resourceChanges
            }
            
            continueButton
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            Image(.frame1)
                .resizable()
                .shadow(radius: 8)
                .overlay(alignment: .topTrailing) {
                    Button {
                        onContinue()
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
                    .padding(8)
                }
        )
        .frame(maxWidth: 380)
    }
    
    private var resultHeader: some View {
        VStack(spacing: 4) {
            Text(operationResult.success ? "MISSION SUCCESS" : "MISSION FAILED")
                .laborFont(18, color: operationResult.success ? .green : .red)
            
            Text(operationResult.outcomeMessage)
                .laborFont(12, color: .white.opacity(0.8), textAlignment: .center)
                .multilineTextAlignment(.center)
        }
    }
    
    private var operationDetails: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Action:")
                    .laborFont(12)
                
                Spacer()
                
                Text(operationResult.actionType.displayName)
                    .laborFont(12, color: .cyan)
            }
            
            HStack {
                Text("Target:")
                    .laborFont(12)
                
                Spacer()
                
                Text(operationResult.targetPOI.type.displayName)
                    .laborFont(12, color: .cyan)
            }
            
            HStack {
                Text("Success Rate:")
                    .laborFont(12)
                
                Spacer()
                
                Text("\(operationResult.successPercentage)%")
                    .laborFont(12, color: probabilityColor)
            }
        }
    }
    
    private var resourceChanges: some View {
        VStack(spacing: 8) {
            if !operationResult.resourcesLost.isEmpty {
                resourceChangeRow("Lost:", operationResult.resourcesLost, isGain: false)
            }
            
            if !operationResult.resourcesGained.isEmpty {
                resourceChangeRow("Gained:", operationResult.resourcesGained, isGain: true)
            }
            
            if operationResult.netValue != 0 {
                HStack {
                    Text("Net Result:")
                        .laborFont(12)
                    
                    Spacer()
                    
                    Text("\(operationResult.netValue > 0 ? "+" : "")\(operationResult.netValue)")
                        .laborFont(12, color: operationResult.netValue > 0 ? .green : .red)
                }
            }
        }
    }
    
    private func resourceChangeRow(_ title: String, _ resource: Resource, isGain: Bool) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .laborFont(12, color: isGain ? .green : .red)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                if resource.money > 0 {
                    resourceIndicator(.coin, resource.money, isGain: isGain)
                }
                if resource.ammo > 0 {
                    resourceIndicator(.ammo, resource.ammo, isGain: isGain)
                }
                if resource.food > 0 {
                    resourceIndicator(.food, resource.food, isGain: isGain)
                }
                if resource.units > 0 {
                    resourceIndicator(.units, resource.units, isGain: isGain)
                }
                
                Spacer()
            }
        }
    }
    
    private func resourceIndicator(_ icon: ImageResource, _ amount: Int, isGain: Bool) -> some View {
        HStack(spacing: 2) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 12)
            
            Text("\(isGain ? "+" : "-")\(amount)")
                .laborFont(10, color: isGain ? .green : .red)
        }
    }
    
    private var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Image(.rectangleButton)
                .resizable()
                .frame(width: 180, height: 50)
                .overlay {
                    Text("Continue")
                        .laborFont(16)
                }
        }
    }
    
    private var probabilityColor: Color {
        let percentage = operationResult.successPercentage
        if percentage >= 70 {
            return .green
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var hasResourceChanges: Bool {
        return !operationResult.resourcesLost.isEmpty || !operationResult.resourcesGained.isEmpty || operationResult.netValue != 0
    }
}

// MARK: - Preview
#Preview {
    let sampleResult = OperationResult(
        actionType: .raid,
        targetPOI: PointOfInterest(type: .village, position: CGPoint(x: 100, y: 100)),
        outcome: .success,
        resourcesLost: Resource(ammo: 2, food: 1),
        resourcesGained: Resource(money: 100, ammo: 5, food: 5, units: 2),
        playerStrength: 15.0,
        enemyStrength: 12.0,
        successProbability: 0.75
    )
    
    OperationResultStandaloneView(operationResult: sampleResult) {
        print("Continue pressed")
    }
}
