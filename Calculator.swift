import SwiftUI

@main
struct CalculatorApp: App {
    init() {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup {
            CalculatorView()
                .frame(width: 260, height: 380)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .windowResizability(.contentSize)
    }
}

struct CalculatorView: View {
    @State private var display = "0"
    @State private var currentNumber: Double = 0
    @State private var previousNumber: Double = 0
    @State private var operation: String? = nil
    @State private var resetDisplay = false
    @State private var activeOp: String? = nil

    let buttons: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Display
            Text(display)
                .font(.system(size: 40, weight: .light, design: .default))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // Buttons
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { button in
                        Button(action: { tap(button) }) {
                            Text(button)
                                .font(.system(size: 20, weight: .medium))
                                .frame(
                                    width: button == "0" ? 116 : 52,
                                    height: 52
                                )
                                .background(buttonColor(button))
                                .foregroundColor(buttonTextColor(button))
                                .cornerRadius(26)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
    }

    func buttonColor(_ button: String) -> Color {
        if ["÷", "×", "−", "+", "="].contains(button) {
            return button == activeOp ? .white : .orange
        }
        if ["C", "±", "%"].contains(button) {
            return Color(nsColor: .systemGray).opacity(0.5)
        }
        return Color(nsColor: .systemGray).opacity(0.25)
    }

    func buttonTextColor(_ button: String) -> Color {
        if ["÷", "×", "−", "+", "="].contains(button) {
            return button == activeOp ? .orange : .white
        }
        return .primary
    }

    func tap(_ button: String) {
        switch button {
        case "C":
            display = "0"
            currentNumber = 0
            previousNumber = 0
            operation = nil
            activeOp = nil
            resetDisplay = false
        case "±":
            if let val = Double(display) {
                currentNumber = -val
                display = formatNumber(currentNumber)
            }
        case "%":
            if let val = Double(display) {
                currentNumber = val / 100
                display = formatNumber(currentNumber)
            }
        case "÷", "×", "−", "+":
            if let val = Double(display) {
                if operation != nil && !resetDisplay {
                    previousNumber = calculate(previousNumber, val, operation!)
                    display = formatNumber(previousNumber)
                } else {
                    previousNumber = val
                }
            }
            operation = button
            activeOp = button
            resetDisplay = true
        case "=":
            if let op = operation, let val = Double(display) {
                let result = calculate(previousNumber, val, op)
                display = formatNumber(result)
                previousNumber = result
                operation = nil
                activeOp = nil
                resetDisplay = true
            }
        case ".":
            if resetDisplay {
                display = "0."
                resetDisplay = false
                activeOp = nil
            } else if !display.contains(".") {
                display += "."
            }
        default: // digits
            if display == "0" || resetDisplay {
                display = button
                resetDisplay = false
                activeOp = nil
            } else {
                display += button
            }
        }
    }

    func calculate(_ a: Double, _ b: Double, _ op: String) -> Double {
        switch op {
        case "÷": return b != 0 ? a / b : 0
        case "×": return a * b
        case "−": return a - b
        case "+": return a + b
        default: return b
        }
    }

    func formatNumber(_ number: Double) -> String {
        if number == number.rounded() && abs(number) < 1e15 {
            return String(format: "%.0f", number)
        }
        let s = String(number)
        return s.count > 12 ? String(format: "%.6g", number) : s
    }
}
