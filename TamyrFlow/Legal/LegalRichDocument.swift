import Foundation

/// Shared sectioned legal-document model (Privacy Policy, Terms of Use).
enum LegalRichDocument {
    struct Section: Identifiable {
        let id: String
        let title: String
        let blocks: [Block]
    }

    enum Block {
        case paragraph(String)
        case bullets([String])
        case contact(label: String, value: String)
    }
}
