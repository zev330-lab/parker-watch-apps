import SwiftUI

struct DadMessagesView: View {
    private let gold = Color(red: 1, green: 0.85, blue: 0.2)

    var body: some View {
        TabView {
            MessagesTab()
                .tabItem { Label("Messages", systemImage: "envelope.fill") }
            HappyThingsTab()
                .tabItem { Label("Happy Things", systemImage: "heart.fill") }
            SuperpowersTab()
                .tabItem { Label("Superpowers", systemImage: "star.fill") }
        }
        .preferredColorScheme(.dark)
        .tint(gold)
    }
}

// MARK: - Messages Tab

private struct MessagesTab: View {
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
                    listView
                }
            }
            .navigationTitle("Messages for Parker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAdding = true }) {
                        Image(systemName: "plus").foregroundColor(gold)
                    }
                }
            }
            .sheet(isPresented: $isAdding) { addSheet }
        }
        .task { await load() }
        .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var listView: some View {
        List {
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
                        .font(.subheadline).foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 32)
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            } else {
                ForEach(messages.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 12) {
                        Text("💌").font(.title3)
                        Text(messages[i]).font(.body).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4).listRowBackground(Color.white.opacity(0.06))
                }
                .onDelete { idx in messages.remove(atOffsets: idx); Task { await save() } }
                .onMove { from, to in messages.move(fromOffsets: from, toOffset: to); Task { await save() } }
            }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("What do you want to tell Parker?")
                        .font(.headline).foregroundColor(.white.opacity(0.8))
                    TextEditor(text: $newMessage)
                        .frame(minHeight: 120).padding(10)
                        .background(Color.white.opacity(0.08)).cornerRadius(10)
                        .foregroundColor(.white).font(.body).tint(gold)
                    Text("Parker's watch will read this out loud to him.")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New message").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { newMessage = ""; isAdding = false }.foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().tint(gold)
                    } else {
                        Button("Send 💌") {
                            let t = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            messages.append(t); newMessage = ""; isAdding = false
                            Task { await save() }
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

    private func load() async {
        do {
            let fetched = try await DadCloudKitStore.fetch()
            await MainActor.run { messages = fetched; isLoading = false }
        } catch {
            await MainActor.run { isLoading = false; saveError = "Couldn't load: \(error.localizedDescription)" }
        }
    }

    private func save() async {
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

// MARK: - Happy Things Tab

private let defaultHappyThings: [String] = [
    "Mom's hugs 🤗", "Dad's hugs 🤗", "My dog 🐶", "Superheroes 🦸",
    "Ben 10 👽", "Karate class 🥋", "Pizza 🍕", "Minecraft ⛏️",
    "Swimming 🏊", "Silly jokes 😂", "Snuggling in bed 😴", "Being brave 💪",
]

private struct HappyThingsTab: View {
    @State private var items: [String] = []
    @State private var newItem = ""
    @State private var isAdding = false
    @State private var isSaving = false
    @State private var lastSaved: Date? = nil
    @State private var saveError: String? = nil
    @State private var isLoading = true

    private let gold = Color(red: 1, green: 0.85, blue: 0.2)
    private let accent = Color.pink

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView().tint(accent)
                        Text("Loading…").font(.subheadline).foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    listView
                }
            }
            .navigationTitle("Parker's Happy Things")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAdding = true }) {
                        Image(systemName: "plus").foregroundColor(accent)
                    }
                }
            }
            .sheet(isPresented: $isAdding) { addSheet }
        }
        .task { await load() }
        .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
    }

    private var listView: some View {
        List {
            if let saved = lastSaved {
                HStack {
                    Image(systemName: "checkmark.icloud.fill").foregroundColor(.green).font(.caption)
                    Text("Saved \(saved, formatter: timeFormatter)").font(.caption).foregroundColor(.white.opacity(0.4))
                }
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            Text("These appear when Parker taps the heart page on his watch.")
                .font(.caption).foregroundColor(.white.opacity(0.4))
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            ForEach(items.indices, id: \.self) { i in
                HStack(spacing: 12) {
                    Text("💛").font(.title3)
                    Text(items[i]).font(.body).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4).listRowBackground(Color.white.opacity(0.06))
            }
            .onDelete { idx in items.remove(atOffsets: idx); Task { await save() } }
            .onMove { from, to in items.move(fromOffsets: from, toOffset: to); Task { await save() } }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add something that makes Parker happy:")
                        .font(.headline).foregroundColor(.white.opacity(0.8))
                    TextField("e.g. Riding his bike 🚲", text: $newItem)
                        .padding(10).background(Color.white.opacity(0.08)).cornerRadius(10)
                        .foregroundColor(.white).font(.body).tint(accent)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New happy thing").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { newItem = ""; isAdding = false }.foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().tint(accent)
                    } else {
                        Button("Add 💛") {
                            let t = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            items.append(t); newItem = ""; isAdding = false
                            Task { await save() }
                        }
                        .foregroundColor(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.3) : accent)
                        .fontWeight(.semibold)
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func load() async {
        if let stored = await HappyThingsCloudKitStore.fetch() {
            await MainActor.run { items = stored; isLoading = false }
        } else {
            await MainActor.run { items = defaultHappyThings; isLoading = false }
            // Seed CloudKit with defaults on first launch
            try? await HappyThingsCloudKitStore.save(defaultHappyThings)
        }
    }

    private func save() async {
        await MainActor.run { isSaving = true }
        do {
            try await HappyThingsCloudKitStore.save(items)
            await MainActor.run { lastSaved = Date(); isSaving = false }
        } catch {
            await MainActor.run { saveError = error.localizedDescription; isSaving = false }
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }
}

// MARK: - Superpowers Tab

private let defaultSuperpowers: [String] = [
    "I am brave.", "I am kind.", "I am a good friend.", "I am smart.",
    "I am strong.", "I try my best.", "I am funny.", "I make people happy.",
    "I am loved.", "I can do hard things.", "I am special.", "I am enough.",
]

private struct SuperpowersTab: View {
    @State private var items: [String] = []
    @State private var newItem = ""
    @State private var isAdding = false
    @State private var isSaving = false
    @State private var lastSaved: Date? = nil
    @State private var saveError: String? = nil
    @State private var isLoading = true

    private let accent = Color(red: 1, green: 0.85, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView().tint(accent)
                        Text("Loading…").font(.subheadline).foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    listView
                }
            }
            .navigationTitle("Parker's Superpowers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAdding = true }) {
                        Image(systemName: "plus").foregroundColor(accent)
                    }
                }
            }
            .sheet(isPresented: $isAdding) { addSheet }
        }
        .task { await load() }
        .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
    }

    private var listView: some View {
        List {
            if let saved = lastSaved {
                HStack {
                    Image(systemName: "checkmark.icloud.fill").foregroundColor(.green).font(.caption)
                    Text("Saved \(saved, formatter: timeFormatter)").font(.caption).foregroundColor(.white.opacity(0.4))
                }
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            Text("These appear when Parker taps the star page on his watch.")
                .font(.caption).foregroundColor(.white.opacity(0.4))
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            ForEach(items.indices, id: \.self) { i in
                HStack(spacing: 12) {
                    Text("⭐️").font(.title3)
                    Text(items[i]).font(.body).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4).listRowBackground(Color.white.opacity(0.06))
            }
            .onDelete { idx in items.remove(atOffsets: idx); Task { await save() } }
            .onMove { from, to in items.move(fromOffsets: from, toOffset: to); Task { await save() } }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add a superpower for Parker:")
                        .font(.headline).foregroundColor(.white.opacity(0.8))
                    TextField("e.g. I am a great listener.", text: $newItem)
                        .padding(10).background(Color.white.opacity(0.08)).cornerRadius(10)
                        .foregroundColor(.white).font(.body).tint(accent)
                    Text("Keep it positive and personal to Parker.")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New superpower").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { newItem = ""; isAdding = false }.foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().tint(accent)
                    } else {
                        Button("Add ⭐️") {
                            let t = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            items.append(t); newItem = ""; isAdding = false
                            Task { await save() }
                        }
                        .foregroundColor(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.3) : accent)
                        .fontWeight(.semibold)
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func load() async {
        if let stored = await SuperpowersCloudKitStore.fetch() {
            await MainActor.run { items = stored; isLoading = false }
        } else {
            await MainActor.run { items = defaultSuperpowers; isLoading = false }
            try? await SuperpowersCloudKitStore.save(defaultSuperpowers)
        }
    }

    private func save() async {
        await MainActor.run { isSaving = true }
        do {
            try await SuperpowersCloudKitStore.save(items)
            await MainActor.run { lastSaved = Date(); isSaving = false }
        } catch {
            await MainActor.run { saveError = error.localizedDescription; isSaving = false }
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }
}
