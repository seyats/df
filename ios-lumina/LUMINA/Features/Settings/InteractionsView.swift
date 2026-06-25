import SwiftUI

/// Interactions screen (Swipe Gestures + Double Tap) - exact to screenshots
struct InteractionsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var leftSwipe: String = "Like"
    @State private var receivedMessagesAction: String = "Sheet"
    @State private var sentMessagesAction: String = "Sheet"

    let swipeOptions = ["Like", "Info"]
    let sheetOptions = ["Sheet", "Full Screen"]   // simplified

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Swipe Gestures
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Swipe Gestures")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            // Left Swipe row with menu
                            HStack {
                                Text("Left Swipe")
                                    .font(.system(size: 17))
                                Spacer()
                                Menu {
                                    ForEach(swipeOptions, id: \.self) { opt in
                                        Button {
                                            leftSwipe = opt
                                        } label: {
                                            HStack {
                                                Text(opt)
                                                if leftSwipe == opt {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(leftSwipe)
                                            .foregroundStyle(LuminaColor.accentBlue)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassCard(radius: 18)

                            Divider()
                                .padding(.leading, 16)

                            // Right Swipe example (static for now)
                            HStack {
                                Text("Right Swipe")
                                    .font(.system(size: 17))
                                Spacer()
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassCard(radius: 18)
                        }
                    }

                    // Double Tap
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Double Tap")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            HStack {
                                Text("Received Messages")
                                    .font(.system(size: 17))
                                Spacer()
                                Menu {
                                    Picker("", selection: $receivedMessagesAction) {
                                        ForEach(sheetOptions, id: \.self) { Text($0) }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(receivedMessagesAction)
                                            .foregroundStyle(LuminaColor.accentBlue)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassCard(radius: 18)

                            Divider().padding(.leading, 16)

                            HStack {
                                Text("Sent Messages")
                                    .font(.system(size: 17))
                                Spacer()
                                Menu {
                                    Picker("", selection: $sentMessagesAction) {
                                        ForEach(sheetOptions, id: \.self) { Text($0) }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(sentMessagesAction)
                                            .foregroundStyle(LuminaColor.accentBlue)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassCard(radius: 18)
                        }
                    }
                }
                .padding(.top, 12)
            }
            .background(LuminaColor.backgroundMain.ignoresSafeArea())
            .navigationTitle("Interactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(LuminaColor.textPrimary)
                            .frame(width: 36, height: 36)
                            .glassCircle()
                    }
                }
            }
        }
    }
}

#Preview {
    InteractionsView()
}