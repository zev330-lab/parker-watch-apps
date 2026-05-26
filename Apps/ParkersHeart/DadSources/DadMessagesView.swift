import SwiftUI

struct DadMessagesView: View {
    @State private var messages: [String] = []
    @State private var newMessage = ""
    @State private var isAdding = false
    @State private var isSaving = false
    @State private var saveError: String? = nil
    @State private var lastSaved: Date? = nil
    @State private var isLoading = true

    private let gold = Color(red: 1, green: 0.85, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView().tint(gold)
                        Text("Loading…").font(.subheadline).foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    messageList
                }
            }
            .navigationTitle("Messages for Parker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAdding = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(gold)
                    }
                }
            }
            .sheet(isPresented: $isAdding) { addSheet }
        }
        .preferredColorScheme(.dark)
        .task { await loadMessages() }
        .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        List {
            // Status row
            if let saved = lastSaved {
                HStack {
                    Image(systemName: "checkmark.icloud.fill").foregroundColor(.green).font(.caption)
                    Text("Saved \(saved, formatter: timeFormatter)")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if messages.isEmpty {
                VStack(spacing: 8) {
                    Text("💌").font(.system(size: 44))
                    Text("Tap + to write your first message for Parker.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(messages.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 12) {
                        Text("💌").font(.title3)
                        Text(messages[i])
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.white.opacity(0.06))
                }
                .onDelete { idx in
                    messages.remove(atOffsets: idx)
                    Task { await saveMessages() }
                }
                .onMove { from, to in
                    messages.move(fromOffsets: from, toOffset: to)
                    Task { await saveMessages() }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Add sheet

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("What do you want to tell Parker?")
                        .font(.headline).foregroundColor(.white.opacity(0.8))

                    TextEditor(text: $newMessage)
                        .frame(minHeight: 120)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.body)
                        .tint(gold)

                    Text("Parker's watch will read this out loud to him.")
                        .font(.caption).foregroundColor(.white.opacity(0.4))

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { newMessage = ""; isAdding = false }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().tint(gold)
                    } else {
                        Button("Send 💌") {
                            let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            messages.append(trimmed)
                            newMessage = ""
                            isAdding = false
                            Task { await saveMessages() }
                        }
                        .foregroundColor(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.3) : gold)
                        .fontWeight(.semibold)
                        .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - CloudKit

    private func loadMessages() async {
        do {
            let fetched = try await DadCloudKitStore.fetch()
            await MainActor.run {
                messages = fetched
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                saveError = "Couldn't load: \(error.localizedDescription)"
            }
        }
    }

    private func saveMessages() async {
        await MainActor.run { isSaving = true }
        do {
            try await DadCloudKitStore.save(messages)
            await MainActor.run { lastSaved = Date(); isSaving = false }
        } catch {
            await MainActor.run { saveError = error.localizedDescription; isSaving = false }
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }
}
