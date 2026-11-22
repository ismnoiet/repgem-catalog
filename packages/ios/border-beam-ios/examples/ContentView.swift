import BorderBeam

struct ContentView: View {
    @State private var text = ""

    var body: some View {
        BorderBeam(shape: .rounded(26), colors: BeamPalette.spectrum) {
            TextField("Build anything...", text: $text)
                .padding()
                .frame(width: 320)
        }
    }
}
