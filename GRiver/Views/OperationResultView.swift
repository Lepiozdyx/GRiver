import SwiftUI

// MARK: - Operation Result View
struct OperationResultView: View {
    @StateObject private var viewModel = OperationResultViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let operationResult: OperationResult
    let onContinue: () -> Void
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Mission Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onContinue()
                    }
                }
            }
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
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onContinue()
                }
            
            // Compact result content
            VStack(spacing: 16) {
                
                // Result Header
                VStack(spacing: 4) {
                    Text(operationResult.success ? "SUCCESS" : "FAILURE")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(operationResult.success ? .green : .red)
                    
                    Text(operationResult.outcomeMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Quick Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(operationResult.actionType.displayName) on \(operationResult.targetPOI.type.displayName)")
                        .font(.headline)
                    
                    Text("Success chance was \(operationResult.successPercentage)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Resource Impact (if any)
                if !operationResult.resourcesLost.isEmpty || !operationResult.resourcesGained.isEmpty {
                    VStack(spacing: 4) {
                        if !operationResult.resourcesLost.isEmpty {
                            Text("Lost: \(formatResourcesCompact(operationResult.resourcesLost))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if !operationResult.resourcesGained.isEmpty {
                            Text("Gained: \(formatResourcesCompact(operationResult.resourcesGained))")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Continue Button
                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
            .frame(maxWidth: 350)
        }
        .onAppear {
            viewModel.processResult(operationResult)
        }
    }
    
    private func formatResourcesCompact(_ resource: Resource) -> String {
        var parts: [String] = []
        
        if resource.money > 0 { parts.append("\(resource.money)💰") }
        if resource.ammo > 0 { parts.append("\(resource.ammo)🔫") }
        if resource.food > 0 { parts.append("\(resource.food)🍖") }
        if resource.units > 0 { parts.append("\(resource.units)👤") }
        
        return parts.isEmpty ? "None" : parts.joined(separator: " ")
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
    
    OperationResultView(operationResult: sampleResult) {
        print("Continue pressed")
    }
}
