import Foundation

/// Keep known failures language independent in saved records.
public protocol LocalizedFailure: LocalizedError {
    var messageKey: String { get }
}

extension LocalizedFailure {
    public var errorDescription: String? { L10n.lookup(messageKey) }
}

/// Shared by SwiftUI, persisted-result presentation and PDF export. Storage identifiers
/// and user-authored text never pass through this API.
public enum L10n {
    public static let languages = ["en", "zh-Hans", "ja", "ko", "de", "es"]

    public static func resolve(_ preferences: [String]) -> String {
        for preference in preferences {
            let code = preference.replacingOccurrences(of: "_", with: "-")
            if code.hasPrefix("zh") { return "zh-Hans" }
            if let match = languages.first(where: { code == $0 || code.hasPrefix($0 + "-") }) { return match }
        }
        return "en"
    }

    @TaskLocal private static var selectedLanguage: String?
    public static var language: String { selectedLanguage ?? resolve(Bundle.main.preferredLocalizations) }
    public static var locale: Locale { Locale(identifier: language) }

    /// Scoped language for report generation and verification; no global preference changes.
    public static func withLanguage<Result>(_ language: String, operation: () throws -> Result) rethrows -> Result {
        try $selectedLanguage.withValue(resolve([language]), operation: operation)
    }

    public static func text(_ message: Message, language: String = L10n.language) -> String {
        let locale = Locale(identifier: resolve([language]))
        let template = lookup(message.key, language: language)
        // Substitute in a single pass, so braces in user text cannot become placeholders.
        let pattern = try! NSRegularExpression(pattern: #"\{(\d+)\}"#)
        let original = template as NSString
        var result = "", offset = 0
        for match in pattern.matches(in: template, range: NSRange(location: 0, length: original.length)) {
            result += original.substring(with: NSRange(location: offset, length: match.range.location - offset))
            let index = Int(original.substring(with: match.range(at: 1)))!
            result += message.arguments.indices.contains(index) ? message.arguments[index].render(locale) : original.substring(with: match.range)
            offset = NSMaxRange(match.range)
        }
        return result + original.substring(from: offset)
    }

    public static func lookup(_ key: String, language: String = L10n.language) -> String {
        let code = resolve([language])
        guard let path = Bundle.module.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    public static func list(_ values: [String]) -> String {
        let formatter = ListFormatter(); formatter.locale = locale
        return formatter.string(from: values) ?? values.joined(separator: ", ")
    }

    public struct Message: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        var key: String
        var arguments: [Argument]
        public init(stringLiteral value: String) { key = value; arguments = [] }
        public init(stringInterpolation: StringInterpolation) {
            key = stringInterpolation.key; arguments = stringInterpolation.arguments
        }
        public struct StringInterpolation: StringInterpolationProtocol {
            var key = ""
            var arguments: [Argument] = []
            public init(literalCapacity: Int, interpolationCount: Int) { key.reserveCapacity(literalCapacity) }
            public mutating func appendLiteral(_ literal: String) { key += literal }
            public mutating func appendInterpolation<T>(_ value: T) {
                key += "{\(arguments.count)}"
                if let value = value as? Double { arguments.append(.number(value, nil)) }
                else if let value = value as? Int { arguments.append(.integer(value)) }
                else { arguments.append(.text(String(describing: value))) }
            }
            public mutating func appendInterpolation(_ value: Double, specifier: String) {
                key += "{\(arguments.count)}"; arguments.append(.number(value, specifier))
            }
        }
    }

    enum Argument {
        case text(String), integer(Int), number(Double, String?)
        func render(_ locale: Locale) -> String {
            switch self {
            case .text(let value): value
            case .integer(let value): value.formatted(.number.grouping(.never).locale(locale))
            case .number(let value, let specifier):
                specifier.map { String(format: $0, locale: locale, value) } ?? value.formatted(.number.locale(locale))
            }
        }
    }
}
