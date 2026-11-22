struct FocusField: View {
    @State private var email = ""
    @FocusState private var focused: Bool

    var body: some View {
        BorderBeam(shape: .rounded(16), active: focused, colors: BeamPalette.aurora) {
            TextField("you@example.com", text: $email)
                .focused($focused)
                .padding()
        }
    }
}
