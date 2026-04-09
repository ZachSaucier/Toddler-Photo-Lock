import UIKit

// MARK: - Challenge

/// A simple arithmetic challenge a toddler cannot solve but a parent can.
struct ParentalGateChallenge: Equatable {
    let question: String
    let answer: Int

    /// Generates a random addition or subtraction problem with operands in 1...19
    /// and a guaranteed positive result.
    static func random() -> ParentalGateChallenge {
        let a = Int.random(in: 1...19)
        let b = Int.random(in: 1...19)

        if Bool.random() {
            return ParentalGateChallenge(question: "What is \(a) + \(b)?", answer: a + b)
        } else {
            let big = max(a, b)
            let small = min(a, b)
            return ParentalGateChallenge(question: "What is \(big) − \(small)?", answer: big - small)
        }
    }

    func isCorrect(_ input: String) -> Bool {
        input.trimmingCharacters(in: .whitespaces) == String(answer)
    }
}

// MARK: - Gate

enum ParentalGate {
    /// Presents a math-challenge alert from `presenter`. Calls `onSuccess` if the
    /// parent answers correctly, does nothing on cancel or wrong answer.
    static func present(from presenter: UIViewController, onSuccess: @escaping () -> Void) {
        let challenge = ParentalGateChallenge.random()

        let alert = UIAlertController(
            title: "Parent check",
            message: challenge.question,
            preferredStyle: .alert
        )

        alert.addTextField { field in
            field.placeholder = "Answer"
            field.keyboardType = .numberPad
        }

        let continueAction = UIAlertAction(title: "Continue", style: .default) { [weak alert] _ in
            let input = alert?.textFields?.first?.text ?? ""
            if challenge.isCorrect(input) {
                onSuccess()
            }
            // Wrong answer: silently dismiss — no hint to the child that a gate exists.
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(continueAction)

        presenter.present(alert, animated: true)
    }
}
