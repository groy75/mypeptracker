import SwiftUI

struct DoseStepperView: View {
    @Binding var value: Double
    var unit: String = "mcg"
    var steps: [Double] = [10, 25, 50, 100]
    var minimum: Double = 0

    @State private var selectedStep: Double = 25

    var body: some View {
        VStack(spacing: 12) {
            // Main value display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatDose(value))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: value)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // +/- buttons
            HStack(spacing: 16) {
                Button {
                    withAnimation(.snappy(duration: 0.15)) {
                        value = max(minimum, value - selectedStep)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 52, height: 44)
                        .background(AppTheme.background)
                        .foregroundStyle(value <= minimum ? AppTheme.textSecondary.opacity(0.3) : AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(value <= minimum)

                // Step size selector
                HStack(spacing: 2) {
                    ForEach(steps, id: \.self) { step in
                        Button {
                            selectedStep = step
                        } label: {
                            Text("±\(formatStep(step))")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedStep == step ? AppTheme.primary : AppTheme.background)
                                .foregroundStyle(selectedStep == step ? .white : AppTheme.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                Button {
                    withAnimation(.snappy(duration: 0.15)) {
                        value += selectedStep
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 52, height: 44)
                        .background(AppTheme.background)
                        .foregroundStyle(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            // Pick the best default step based on current value
            if value >= 1000 {
                selectedStep = steps.last ?? 100
            } else if value >= 200 {
                selectedStep = steps.dropFirst().first ?? 25
            }
        }
    }

    private func formatDose(_ dose: Double) -> String {
        if dose == dose.rounded() {
            return String(format: "%.0f", dose)
        }
        return String(format: "%.1f", dose)
    }

    private func formatStep(_ step: Double) -> String {
        if step >= 1000 {
            return String(format: "%.0fk", step / 1000)
        }
        if step == step.rounded() {
            return String(format: "%.0f", step)
        }
        return String(format: "%.1f", step)
    }
}
