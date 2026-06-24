import SwiftUI

/// Экран 7: «Когда ваш день рождения?»
struct BirthdayView: View {
    @Binding var date: Date
    var onContinue: () -> Void

    private let calendar = Calendar.current
    @State private var selectedDay: Int = 1
    @State private var selectedMonth: Int = 1
    @State private var selectedYear: Int = 2000

    var body: some View {
        VStack(spacing: 0) {
            Text("Когда ваш день рождения?")
                .font(LuminaFont.h1)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 80)

            Text("Ваш день рождения не будет показываться публично.")
                .font(.system(size: 15))
                .foregroundStyle(.gray)
                .padding(.top, 8)

            // Выбранная дата
            Text(formatDate())
                .font(LuminaFont.h2)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 32)

            // Колёса выбора
            HStack(spacing: 0) {
                Picker("День", selection: $selectedDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)

                Picker("Месяц", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthName(month)).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120)

                Picker("Год", selection: $selectedYear) {
                    ForEach(1940...2020, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
            }
            .frame(height: 200)
            .onChange(of: selectedDay) { updateDate() }
            .onChange(of: selectedMonth) { updateDate() }
            .onChange(of: selectedYear) { updateDate() }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onContinue()
            }) {
                Text("Продолжить")
                    .font(LuminaFont.body)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LuminaColor.accentBlue, in: Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
        .onAppear {
            let comps = calendar.dateComponents([.day, .month, .year], from: date)
            selectedDay = comps.day ?? 1
            selectedMonth = comps.month ?? 1
            selectedYear = comps.year ?? 2000
        }
    }

    private func updateDate() {
        let comps = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        if let newDate = calendar.date(from: comps) {
            date = newDate
        }
    }

    private func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    private func monthName(_ month: Int) -> String {
        let names = [
            "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
            "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
        ]
        return month >= 1 && month <= 12 ? names[month - 1] : ""
    }
}
