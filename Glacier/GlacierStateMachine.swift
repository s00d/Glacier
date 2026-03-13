enum GlacierState: Equatable {
    case closed
    case hiddenOpen
    case allOpen
    case editing
}

enum GlacierInput {
    case primaryClick
    case alternateClick
    case dismiss
    case escape
    case enterEditing
    case finishEditing
}

struct GlacierStateMachine {
    private(set) var state: GlacierState = .closed

    @discardableResult
    mutating func handle(_ input: GlacierInput) -> GlacierState {
        switch (state, input) {
        case (.closed, .primaryClick):
            state = .hiddenOpen
        case (.hiddenOpen, .primaryClick), (.allOpen, .primaryClick), (.editing, .primaryClick):
            state = .closed

        case (.closed, .alternateClick):
            state = .allOpen
        case (.hiddenOpen, .alternateClick):
            state = .allOpen
        case (.allOpen, .alternateClick), (.editing, .alternateClick):
            state = .closed

        case (.editing, .dismiss):
            break
        case (_, .dismiss), (_, .escape), (_, .finishEditing):
            state = .closed

        case (_, .enterEditing):
            state = .editing
        }

        return state
    }
}
