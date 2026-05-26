import Foundation

/// Lightweight JSON persistence for collectibles, progress, lists.
public struct StorageKit {

    /// Saves any Codable value to UserDefaults.
    public static func save<T: Codable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Loads a Codable value from UserDefaults, returning a default if absent.
    public static func load<T: Codable>(_ type: T.Type, key: String, default fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else { return fallback }
        return value
    }

    /// Removes a persisted value.
    public static func clear(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
