import SwiftUI

extension Text {
    func laborFont(
        _ size: CGFloat,
        color: Color = .white,
        textAlignment: TextAlignment = .center
    ) -> some View {
        let baseFont = UIFont(name: "LaborUnion-Regular", size: size) ?? UIFont.systemFont(ofSize: size, weight: .regular)
        
        let scaledFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)

        return self
            .font(Font(scaledFont))
            .foregroundStyle(color)
            .shadow(color: .black, radius: 1)
            .multilineTextAlignment(textAlignment)
    }
}

struct Extensions: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .laborFont(32)
    }
}

#Preview {
    Extensions()
}
