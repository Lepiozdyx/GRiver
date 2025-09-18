import Foundation
import Combine

// MARK: - Operation Result Impact
enum OperationImpact: String, CaseIterable {
    case minimal = "minimal"
    case moderate = "moderate"
    case significant = "significant"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal Impact"
        case .moderate: return "Moderate Impact"
        case .significant: return "Significant Impact"
        case .critical: return "Critical Impact"
        }
    }
    
    var color: String {
        switch self {
        case .minimal: return "gray"
        case .moderate: return "blue"
        case .significant: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Operation Result View Model
class OperationResultViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var operationResult: OperationResult?
    @Published var currentGameState: GameState?
    @Published var showDetailedAnalysis: Bool = false
    @Published var showRecommendations: Bool = false
    
    // Analysis results
    @Published var impactLevel: OperationImpact = .minimal
    @Published var strategicAnalysis: String = ""
    @Published var nextStepRecommendations: [String] = []
    @Published var riskAssessment: String = ""
    
    // MARK: - Dependencies
    private var gameStateManager: GameStateManager?
    
    // MARK: - Initialization
    init() {
        // Empty init for standalone usage
    }
    
    convenience init(gameStateManager: GameStateManager) {
        self.init()
        self.gameStateManager = gameStateManager
        updateCurrentGameState()
    }
    
    // MARK: - Result Processing
    func processResult(_ result: OperationResult) {
        operationResult = result
        updateCurrentGameState()
        analyzeOperationImpact(result)
        generateStrategicAnalysis(result)
        generateRecommendations(result)
        assessCurrentRisks(result)
    }
    
    private func updateCurrentGameState() {
        currentGameState = gameStateManager?.exportGameState()
    }
    
    // MARK: - Impact Analysis
    private func analyzeOperationImpact(_ result: OperationResult) {
        let resourceValue = abs(result.netValue)
        let wasHighRisk = result.wasHighRisk
        let affectsGameState = result.actionType.isPermanent
        
        if result.success {
            if affectsGameState && resourceValue > 500 {
                impactLevel = .critical
            } else if wasHighRisk || resourceValue > 300 {
                impactLevel = .significant
            } else if resourceValue > 100 {
                impactLevel = .moderate
            } else {
                impactLevel = .minimal
            }
        } else {
            if wasHighRisk || resourceValue > 200 {
                impactLevel = .significant
            } else if resourceValue > 50 {
                impactLevel = .moderate
            } else {
                impactLevel = .minimal
            }
        }
    }
    
    // MARK: - Strategic Analysis
    private func generateStrategicAnalysis(_ result: OperationResult) {
        var analysis = ""
        
        // Success/Failure context
        if result.success {
            analysis += "Operation succeeded against \(result.targetPOI.type.displayName). "
            
            if result.wasHighRisk {
                analysis += "Despite low odds, your forces proved superior. "
            }
            
            // Resource analysis
            if result.netValue > 0 {
                analysis += "Net resource gain of \(result.netValue) value strengthens your position. "
            }
            
            // Action-specific analysis
            switch result.actionType {
            case .capture:
                analysis += "Capturing this location provides strategic control and eliminates enemy presence. "
            case .destruction:
                analysis += "Destroying this target weakens overall enemy forces by 10%. "
            case .raid, .robbery:
                analysis += "Hit-and-run tactics have weakened enemy defenses while gathering resources. "
            }
            
        } else {
            analysis += "Operation failed against \(result.targetPOI.type.displayName). "
            
            if !result.wasHighRisk {
                analysis += "Despite favorable odds, enemy defenses held strong. "
            } else {
                analysis += "High-risk operation failed as expected. "
            }
            
            analysis += "Resource losses of \(result.totalLoss) value impact operational capacity. "
        }
        
        // Alert level impact
        if let gameState = currentGameState {
            let alertPercent = gameState.alertPercentage
            if alertPercent >= 90 {
                analysis += "CRITICAL: Alert level at \(alertPercent)% - base discovery imminent!"
            } else if alertPercent >= 70 {
                analysis += "WARNING: Alert level at \(alertPercent)% - enemy actively searching."
            } else if alertPercent >= 50 {
                analysis += "Alert level at \(alertPercent)% - increased enemy vigilance."
            }
        }
        
        strategicAnalysis = analysis
    }
    
    // MARK: - Recommendations Generation
    private func generateRecommendations(_ result: OperationResult) {
        var recommendations: [String] = []
        
        guard let gameState = currentGameState else {
            nextStepRecommendations = ["Unable to analyze game state"]
            return
        }
        
        // Resource-based recommendations
        if gameState.resources.units < 3 {
            recommendations.append("Recruit more units before next operation")
        }
        
        if gameState.resources.ammo < 10 {
            recommendations.append("Stock up on ammunition for better success rates")
        }
        
        if gameState.resources.food < 15 {
            recommendations.append("Purchase food supplies for sustained operations")
        }
        
        // Alert level recommendations
        let alertLevel = gameState.alertPercentage
        if alertLevel >= 80 {
            recommendations.append("URGENT: Consider lying low - base discovery risk critical")
        } else if alertLevel >= 60 {
            recommendations.append("Focus on high-value targets to maximize remaining operations")
        }
        
        // Success/failure specific recommendations
        if result.success {
            switch result.actionType {
            case .capture:
                recommendations.append("Expand operations from newly secured position")
            case .destruction:
                recommendations.append("Take advantage of reduced enemy strength")
            case .raid, .robbery:
                recommendations.append("Consider capturing this weakened target")
            }
            
            if result.wasHighRisk {
                recommendations.append("Successful high-risk operation - consider similar tactics")
            }
        } else {
            recommendations.append("Strengthen forces before attempting similar operations")
            
            if result.wasHighRisk {
                recommendations.append("Target easier objectives to rebuild resources")
            } else {
                recommendations.append("Unexpected failure - reassess enemy capabilities")
            }
        }
        
        // Strategic recommendations
        let activePOIs = gameState.activePOIs.count
        let totalPOIs = gameState.totalPOIs
        let progress = Double(totalPOIs - activePOIs) / Double(totalPOIs)
        
        if progress >= 0.8 {
            recommendations.append("Victory near - focus on remaining high-value targets")
        } else if progress >= 0.5 {
            recommendations.append("Good progress - maintain momentum")
        } else if progress < 0.3 {
            recommendations.append("Early game - focus on resource gathering operations")
        }
        
        // Base upgrade recommendations
        let baseManager = BaseManager()
        if gameState.resources.money >= 500 && !baseManager.getBuildingInfo(BuildingType.storage).isMaxLevel {
            recommendations.append("Consider upgrading storage for higher resource limits")
        }
        
        if gameState.resources.units >= baseManager.maxUnits * Int(0.8) && !baseManager.getBuildingInfo(BuildingType.barracks).isMaxLevel {
            recommendations.append("Upgrade barracks to recruit more units")
        }
        
        nextStepRecommendations = recommendations
    }
    
    // MARK: - Risk Assessment
    private func assessCurrentRisks(_ result: OperationResult) {
        guard let gameState = currentGameState else {
            riskAssessment = "Unable to assess risks"
            return
        }
        
        var risks: [String] = []
        
        // Alert level risks
        let alertLevel = gameState.alertPercentage
        if alertLevel >= 90 {
            risks.append("CRITICAL: Base discovery imminent (Alert: \(alertLevel)%)")
        } else if alertLevel >= 70 {
            risks.append("HIGH: Enemy actively hunting your base (Alert: \(alertLevel)%)")
        } else if alertLevel >= 50 {
            risks.append("MEDIUM: Increased enemy patrols (Alert: \(alertLevel)%)")
        } else {
            risks.append("LOW: Minimal enemy awareness (Alert: \(alertLevel)%)")
        }
        
        // Resource risks
        if gameState.resources.units <= 2 {
            risks.append("CRITICAL: Very few units remaining")
        }
        
        if gameState.resources.ammo <= 5 && gameState.resources.food <= 5 {
            risks.append("HIGH: Low supplies limit operation effectiveness")
        }
        
        // Strategic risks
        let remainingTargets = gameState.activePOIs.count
        if remainingTargets <= 2 && alertLevel >= 60 {
            risks.append("Time pressure - few targets remain, high alert")
        }
        
        // Recent failure impact
        if !result.success && result.actionType.isPermanent {
            risks.append("Failed permanent operation - enemy defenses strengthened")
        }
        
        riskAssessment = risks.isEmpty ? "No significant risks detected" : risks.joined(separator: "\n")
    }
    
    // MARK: - Display Properties
    var resultTitle: String {
        guard let result = operationResult else { return "Operation Result" }
        return result.success ? "MISSION SUCCESS" : "MISSION FAILED"
    }
    
    var resultColor: String {
        guard let result = operationResult else { return "gray" }
        return result.success ? "green" : "red"
    }
    
    var operationSummary: String {
        guard let result = operationResult else { return "" }
        
        var summary = "\(result.actionType.displayName) on \(result.targetPOI.type.displayName)"
        summary += "\nSuccess probability was \(result.successPercentage)%"
        
        if result.success {
            summary += "\nYour forces proved superior"
        } else {
            summary += "\nEnemy defenses held strong"
        }
        
        return summary
    }
    
    var resourceChangesSummary: String {
        guard let result = operationResult else { return "" }
        
        var summary = ""
        
        if !result.resourcesLost.isEmpty {
            summary += "Resources Lost:\n"
            summary += formatResourceChange(result.resourcesLost, positive: false)
            summary += "\n"
        }
        
        if !result.resourcesGained.isEmpty {
            summary += "Resources Gained:\n"
            summary += formatResourceChange(result.resourcesGained, positive: true)
            summary += "\n"
        }
        
        let netValue = result.netValue
        if netValue != 0 {
            summary += "Net Change: \(netValue > 0 ? "+" : "")\(netValue) value"
        }
        
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatResourceChange(_ resource: Resource, positive: Bool) -> String {
        var parts: [String] = []
        let prefix = positive ? "+" : "-"
        
        if resource.money > 0 { parts.append("\(prefix)\(resource.money) money") }
        if resource.ammo > 0 { parts.append("\(prefix)\(resource.ammo) ammo") }
        if resource.food > 0 { parts.append("\(prefix)\(resource.food) food") }
        if resource.units > 0 { parts.append("\(prefix)\(resource.units) units") }
        
        return parts.joined(separator: ", ")
    }
    
    var gameStateSummary: String {
        guard let gameState = currentGameState else { return "Game state unavailable" }
        
        let progress = Int(gameState.completionPercentage * 100)
        let activePOIs = gameState.activePOIs.count
        let alertLevel = gameState.alertPercentage
        
        return """
        Mission Progress: \(progress)%
        Remaining Targets: \(activePOIs)
        Alert Level: \(alertLevel)%
        Total Resources: \(gameState.resources.totalValue)
        """
    }
    
    // MARK: - Action Methods
    func showDetailedView() {
        showDetailedAnalysis = true
    }
    
    func hideDetailedView() {
        showDetailedAnalysis = false
    }
    
    func showRecommendationsView() {
        showRecommendations = true
    }
    
    func hideRecommendationsView() {
        showRecommendations = false
    }
    
    // MARK: - Validation
    var hasValidResult: Bool {
        return operationResult != nil
    }
    
    var canShowAnalysis: Bool {
        return hasValidResult && currentGameState != nil
    }
    
    // MARK: - Reset
    func reset() {
        operationResult = nil
        currentGameState = nil
        showDetailedAnalysis = false
        showRecommendations = false
        strategicAnalysis = ""
        nextStepRecommendations = []
        riskAssessment = ""
        impactLevel = .minimal
    }
}
