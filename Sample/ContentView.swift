import SwiftUI

struct ContentView: View {
    var buttonAction: () -> Void
    @Binding var name: String?
    
    var body: some View {
        if name != nil {
            Text("Hello: \(name ?? "")")
                .foregroundColor(Color.white)
                .font(.caption2)
        } else {
            Button(action: buttonAction, label: {
                HStack {
                    Text("Authorize")
                        .foregroundColor(Color.white)
                    Image(systemName: "faceid")
                        .foregroundColor(Color.white)
                }
                .frame(width: 200, height: 44, alignment: .center)
                .background(Color.green)
                .cornerRadius(4)
            })
        }
    }
}
