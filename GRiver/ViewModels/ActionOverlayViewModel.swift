import Foundation
import Combine

// MARK: - Action Overlay View Model
class ActionOverlayViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedPOI: PointOfInterest?
    @Published var playerResources: Resource = Resource.zero
    @Published var actionAnalyses: [ActionType: OperationAnalysis] = [:]
    @Published var isAnalyzing: Bool = false
    @Published var showExecutionConfirm: Bool = false
    @Published var selectedAction: ActionType?
    
    // Execution state
    @Published var isExecuting: Bool = false
    @Published var executionResult: OperationResult?
    @Published var showResult: Bool = false
    
    // MARK: - Dependencies
    private var gameStateManager: GameStateManager?
    private let combatCalculator = CombatCalculator.self
    
    // MARK: - Computed Properties
    var isVisible: Bool {
        return selectedPOI != nil
    }
    
    var targetInfo: String {
        guard let poi = selectedPOI else { return "" }
        return "\(poi.type.displayName) - Defense: \(poi.totalDefense), Units: \(poi.currentUnits)"
    }
    
    var availableActions: [ActionType] {
        guard let poi = selectedPOI else { return [] }
        
        return ActionType.allCases.filter { actionType in
            let validation = ActionValidator.canPerform(actionType, with: playerResources, against: poi)
            return validation.isValid
        }
    }
    
    var unavailableActions: [ActionType] {
        guard let poi = selectedPOI else { return [] }
        
        return ActionType.allCases.filter { actionType in
            let validation = ActionValidator.canPerform(actionType, with: playerResources, against: poi)
            return !validation.isValid
        }
    }
    
    // MARK: - Initialization
    init() {
        // Empty init for standalone usage
    }
    
    convenience init(gameStateManager: GameStateManager) {
        self.init()
        self.gameStateManager = gameStateManager
        refreshPlayerResources()
    }
    
    // MARK: - POI Selection
    func selectPOI(_ poi: PointOfInterest) {
        selectedPOI = poi
        refreshPlayerResources()
        analyzeAllActions()
    }
    
    func deselectPOI() {
        selectedPOI = nil
        actionAnalyses.removeAll()
        selectedAction = nil
        hideExecutionConfirm()
        hideResult()
    }
    
    // MARK: - Data Refresh
    private func refreshPlayerResources() {
        if let gameManager = gameStateManager {
            playerResources = gameManager.currentResources
        }
    }
    
    // MARK: - Action Analysis
    private func analyzeAllActions() {
        guard let poi = selectedPOI else { return }
        
        isAnalyzing = true
        actionAnalyses.removeAll()
        
        // Analyze each action type
        for actionType in ActionType.allCases {
            let analysis = combatCalculator.analyzeOperation(
                actionType: actionType,
                playerResources: playerResources,
                targetPOI: poi
            )
            actionAnalyses[actionType] = analysis
        }
        
        isAnalyzing = false
    }
    
    func getAnalysis(for actionType: ActionType) -> OperationAnalysis? {
        return actionAnalyses[actionType]
    }
    
    func getSuccessProbability(for actionType: ActionType) -> Double {
        return actionAnalyses[actionType]?.successProbability ?? 0.0
    }
    
    func getSuccessPercentage(for actionType: ActionType) -> Int {
        return actionAnalyses[actionType]?.successPercentage ?? 0
    }
    
    func getRiskAssessment(for actionType: ActionType) -> String {
        return actionAnalyses[actionType]?.riskAssessment ?? "Unknown risk"
    }
    
    // MARK: - Action Selection
    func selectAction(_ actionType: ActionType) {
        guard availableActions.contains(actionType) else { return }
        
        selectedAction = actionType
        showExecutionConfirm = true
    }
    
    func showExecutionConfirm(for actionType: ActionType) {
        selectedAction = actionType
        showExecutionConfirm = true
    }
    
    func hideExecutionConfirm() {
        showExecutionConfirm = false
        selectedAction = nil
    }
    
    // MARK: - Action Execution
    func executeSelectedAction() {
        guard let actionType = selectedAction,
              let poi = selectedPOI,
              let gameManager = gameStateManager else { return }
        
        hideExecutionConfirm()
        isExecuting = true
        
        // Execute operation through game manager
        let result = gameManager.executeOperation(actionType: actionType, targetPOI: poi)
        
        // Update local state
        executionResult = result
        refreshPlayerResources()
        
        isExecuting = false
        showResult = true
        
        // Update POI if it was captured or destroyed
        if result.success {
            switch actionType {
            case .capture, .destruction:
                // POI state has changed, need to refresh
                if let updatedPOI = gameManager.getPOI(withID: poi.id) {
                    selectedPOI = updatedPOI
                }
            default:
                // For raid and robbery, POI stays operational but might be weakened
                break
            }
        }
        
        // Re-analyze actions with new resources/POI state
        analyzeAllActions()
    }
    
    func hideResult() {
        showResult = false
        executionResult = nil
    }
    
    // MARK: - Action Validation
    func canPerformAction(_ actionType: ActionType) -> Bool {
        guard let poi = selectedPOI else { return false }
        let validation = ActionValidator.canPerform(actionType, with: playerResources, against: poi)
        return validation.isValid
    }
    
    func getValidationError(for actionType: ActionType) -> String {
        guard let poi = selectedPOI else { return "No target selected" }
        let validation = ActionValidator.canPerform(actionType, with: playerResources, against: poi)
        return validation.errorMessage
    }
    
    // MARK: - Strategic Recommendations
    func getBestAction() -> ActionType? {
        guard let poi = selectedPOI else { return nil }
        return combatCalculator.getBestActionType(playerResources: playerResources, targetPOI: poi)
    }
    
    func getRecommendedActions() -> [ActionType] {
        let available = availableActions
        return available.filter { actionType in
            if let analysis = actionAnalyses[actionType] {
                return analysis.isWorthwhile
            }
            return false
        }.sorted { first, second in
            let firstProb = actionAnalyses[first]?.successProbability ?? 0.0
            let secondProb = actionAnalyses[second]?.successProbability ?? 0.0
            return firstProb > secondProb
        }
    }
    
    // MARK: - Cost Information
    func getActionCost(_ actionType: ActionType) -> Resource {
        return actionType.baseCost
    }
    
    func getExpectedReward(_ actionType: ActionType) -> Resource {
        return actionAnalyses[actionType]?.expectedGain ?? Resource.zero
    }
    
    func getExpectedLoss(_ actionType: ActionType) -> Resource {
        return actionAnalyses[actionType]?.expectedLoss ?? Resource.zero
    }
    
    // MARK: - UI Support Methods
    func getActionStatusColor(_ actionType: ActionType) -> ActionStatusColor {
        if !canPerformAction(actionType) {
            return .unavailable
        }
        
        let probability = getSuccessProbability(for: actionType)
        if probability >= 0.7 {
            return .good
        } else if probability >= 0.5 {
            return .caution
        } else {
            return .dangerous
        }
    }
    
    func shouldShowAction(_ actionType: ActionType) -> Bool {
        // Show all actions, but disable unavailable ones
        return true
    }
    
    func getActionDescription(_ actionType: ActionType) -> String {
        guard let analysis = actionAnalyses[actionType] else {
            return actionType.description
        }
        
        if analysis.isViable {
            return "\(actionType.description) - \(analysis.successPercentage)% success chance"
        } else {
            return "\(actionType.description) - Not available"
        }
    }
    
    // MARK: - Confirmation Dialog Support
    var confirmationTitle: String {
        guard let action = selectedAction else { return "" }
        return "Execute \(action.displayName)?"
    }
    
    var confirmationMessage: String {
        guard let action = selectedAction,
              let poi = selectedPOI,
              let analysis = actionAnalyses[action] else { return "" }
        
        var message = "Target: \(poi.type.displayName)\n"
        message += "Success chance: \(analysis.successPercentage)%\n"
        message += "Risk: \(analysis.riskAssessment)\n"
        
        let cost = getActionCost(action)
        if !cost.isEmpty {
            message += "Cost: "
            var costItems: [String] = []
            if cost.ammo > 0 { costItems.append("\(cost.ammo) ammo") }
            if cost.food > 0 { costItems.append("\(cost.food) food") }
            if cost.units > 0 { costItems.append("\(cost.units) units") }
            message += costItems.joined(separator: ", ")
        }
        
        return message
    }
    
    // MARK: - Cleanup
    func reset() {
        deselectPOI()
        actionAnalyses.removeAll()
        isAnalyzing = false
        isExecuting = false
    }
}

// MARK: - Action Status Color Enum
enum ActionStatusColor: String, CaseIterable {
    case good = "good"
    case caution = "caution"
    case dangerous = "dangerous"
    case unavailable = "unavailable"
    
    var displayColor: String {
        switch self {
        case .good: return "green"
        case .caution: return "yellow"
        case .dangerous: return "orange"
        case .unavailable: return "gray"
        }
    }
}
