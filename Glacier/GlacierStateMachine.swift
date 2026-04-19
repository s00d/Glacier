enum GlacierState: Equatable {
    case closed
    case open
    case editing
}

enum GlacierInput {
    case primaryClick
    case alternateClick
    case escape
    case enterEditing
    case finishEditing
}

struct GlacierStateMachine {
    private(set) var state: GlacierState = .closed

    @discardableResult
    mutating func handle(_ input: GlacierInput) -> GlacierState {
        switch (state, input) {
        case (.closed, .primaryClick), (.closed, .alternateClick):
            state = .open
        case (.open, .primaryClick), (.open, .alternateClick):
            state = .closed

        case (.editing, .primaryClick), (.editing, .alternateClick):
            break

        case (_, .escape), (_, .finishEditing):
            state = .closed

        case (_, .enterEditing):
            state = .editing
        }

        return state
    }
}

extension GlacierStateMachine {
    /// Used by unit tests to seed uncommon states without simulating long click sequences.
    mutating func setStateForTesting(_ newState: GlacierState) {
        state = newState
    }
}
