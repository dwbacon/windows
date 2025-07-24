
import SwiftUI

struct PreviewView: View {
    var image: NSImage?

    var body: some View {
        if let image = image {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Text("No preview available")
        }
    }
}
