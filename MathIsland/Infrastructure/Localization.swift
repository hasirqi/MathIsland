import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: .main, value: key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}

extension RelationshipType {
    var localizedName: String {
        L10n.text("relationship.\(rawValue)")
    }
}

extension LearningErrorType {
    var localizedName: String {
        L10n.text("error.\(rawValue)")
    }
}