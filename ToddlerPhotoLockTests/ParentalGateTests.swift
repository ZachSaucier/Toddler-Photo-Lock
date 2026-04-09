import XCTest
@testable import ToddlerPhotoLock

final class ParentalGateTests: XCTestCase {

    // MARK: - Challenge generation

    func testRandomChallengeHasPositiveAnswer() {
        for _ in 0..<200 {
            let challenge = ParentalGateChallenge.random()
            XCTAssertGreaterThanOrEqual(challenge.answer, 0, "Answer must be non-negative: \(challenge.question)")
        }
    }

    func testRandomChallengeQuestionIsNonEmpty() {
        for _ in 0..<50 {
            let challenge = ParentalGateChallenge.random()
            XCTAssertFalse(challenge.question.isEmpty)
        }
    }

    func testRandomChallengeAnswerIsEmbeddedInQuestion() {
        // The question must be self-consistent: evaluating the operands should
        // produce the stored answer. We verify by parsing the question string.
        for _ in 0..<200 {
            let challenge = ParentalGateChallenge.random()
            let computed = evaluate(challenge.question)
            XCTAssertEqual(computed, challenge.answer, "Mismatch for: \(challenge.question)")
        }
    }

    func testRandomChallengeOperandsAreInExpectedRange() {
        for _ in 0..<200 {
            let challenge = ParentalGateChallenge.random()
            let operands = extractOperands(from: challenge.question)
            XCTAssertEqual(operands.count, 2, "Expected two operands in: \(challenge.question)")
            for operand in operands {
                XCTAssertTrue((1...19).contains(operand), "Operand \(operand) out of range in: \(challenge.question)")
            }
        }
    }

    // MARK: - isCorrect

    func testCorrectAnswerAsStringPasses() {
        let challenge = ParentalGateChallenge(question: "What is 3 + 4?", answer: 7)
        XCTAssertTrue(challenge.isCorrect("7"))
    }

    func testCorrectAnswerWithLeadingTrailingSpacesPasses() {
        let challenge = ParentalGateChallenge(question: "What is 3 + 4?", answer: 7)
        XCTAssertTrue(challenge.isCorrect("  7  "))
    }

    func testWrongAnswerFails() {
        let challenge = ParentalGateChallenge(question: "What is 3 + 4?", answer: 7)
        XCTAssertFalse(challenge.isCorrect("8"))
    }

    func testEmptyInputFails() {
        let challenge = ParentalGateChallenge(question: "What is 3 + 4?", answer: 7)
        XCTAssertFalse(challenge.isCorrect(""))
    }

    func testNonNumericInputFails() {
        let challenge = ParentalGateChallenge(question: "What is 3 + 4?", answer: 7)
        XCTAssertFalse(challenge.isCorrect("seven"))
    }

    func testZeroAnswerIsHandledCorrectly() {
        // Subtraction where operands are equal produces 0
        let challenge = ParentalGateChallenge(question: "What is 5 − 5?", answer: 0)
        XCTAssertTrue(challenge.isCorrect("0"))
        XCTAssertFalse(challenge.isCorrect(""))
    }

    // MARK: - Equatable

    func testChallengesWithSameValuesAreEqual() {
        let a = ParentalGateChallenge(question: "What is 2 + 3?", answer: 5)
        let b = ParentalGateChallenge(question: "What is 2 + 3?", answer: 5)
        XCTAssertEqual(a, b)
    }

    func testChallengesWithDifferentAnswersAreNotEqual() {
        let a = ParentalGateChallenge(question: "What is 2 + 3?", answer: 5)
        let b = ParentalGateChallenge(question: "What is 2 + 3?", answer: 6)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Helpers

    /// Parses "What is A + B?" or "What is A − B?" and returns the result.
    private func evaluate(_ question: String) -> Int? {
        if question.contains("+") {
            let parts = question.components(separatedBy: "+")
            guard parts.count == 2,
                  let a = extractLastInt(from: parts[0]),
                  let b = extractFirstInt(from: parts[1]) else { return nil }
            return a + b
        } else if question.contains("−") {
            let parts = question.components(separatedBy: "−")
            guard parts.count == 2,
                  let a = extractLastInt(from: parts[0]),
                  let b = extractFirstInt(from: parts[1]) else { return nil }
            return a - b
        }
        return nil
    }

    private func extractLastInt(from string: String) -> Int? {
        string.components(separatedBy: .whitespaces).compactMap(Int.init).last
    }

    private func extractFirstInt(from string: String) -> Int? {
        string.components(separatedBy: .whitespaces).compactMap(Int.init).first
    }

    private func extractOperands(from question: String) -> [Int] {
        let separator: String = question.contains("+") ? "+" : "−"
        let parts = question.components(separatedBy: separator)
        return parts.compactMap { part in
            part.components(separatedBy: .whitespaces).compactMap(Int.init).first
        }
    }
}
