import Foundation

struct VocabEntry: Codable, Hashable {
    let w: String  // word
    let p: String  // part of speech
    let d: String  // definition
    let e: String  // example sentence
}

enum ContentBank {
    static let vocab: [VocabEntry] = load("vocab")
    static let roasts: [String] = load("roasts")
    static let roastsClean: [String] = load("roasts_clean")
    static let affirmations: [String] = load("affirmations")
    static let fortunes: [String] = load("fortunes")
    static let wisdomBible: [WisdomEntry] = load("wisdom_bible")
    static let wisdomStoic: [WisdomEntry] = load("wisdom_stoic")

    private static func load<T: Decodable>(_ name: String) -> T {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(T.self, from: data)
        else {
            fatalError("Missing or malformed content bank: \(name).json")
        }
        return decoded
    }
}
