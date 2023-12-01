//
//  ContentView.swift
//  First App
//
//  Created by Eric Waldbaum on 11/29/23.
//  Thanks to https://www.linkedin.com/learning/building-your-first-ios-17-app/how-to-build-an-app-in-an-afternoon?u=67682169 led by Todd Perkins for teaching the base of this app
//  Thanks to ChatGPT for assisting with additional features I came up with.
//  11/29/2023: Followed tutorial for base of app
//  11/30-12/1/2023: Added enhancements including: improved UX with string updates, stricter valid inputs, buttons with a11y, theming, total amount displayed
//  TO DO: Consider Clear (X) button to clear textfield, Custom Tip textfield, custom notch slider, avoiding jump when textfield has focus, underline textfield, adding test automation, target non-iPhone 15 Pro
//

import SwiftUI

struct ContentView: View {
    @State var total = ""
    @State var tipPercent = 15.0
    @State private var isTextFieldFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .imageScale(.large)
                    .background(Color.green)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    .font(.title)

                Text("Got Tip?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                Spacer()
            }
            VStack(spacing: 0) {
                HStack {
                    DecimalTextField(placeholder: "Sub-total Amount", text: $total)
                        .frame(height: 40)
                }
                Spacer()
            }

            // add label to make clearer
            Text("Select Tip Amount:")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.bottom, 10)

            HStack(spacing: 32) {
                // Adding buttons for 0%, 10%, 15%, and 20%
                TipButton(value: 0, tipPercent: $tipPercent)
                    .accessibilityIdentifier("btnZeroPercentTip")
                TipButton(value: 10, tipPercent: $tipPercent)
                    .accessibilityIdentifier("btnTenPercentTip")
                TipButton(value: 15, tipPercent: $tipPercent)
                    .accessibilityIdentifier("btnFifteenPercentTip")
                TipButton(value: 20, tipPercent: $tipPercent)
                    .accessibilityIdentifier("btnTwentyPercentTip")
            }

            HStack {
                Slider(value: $tipPercent, in: 0...30, step: 1.0)
                    .accentColor(.green)
                Text("\(Int(tipPercent))%")
            }
            Spacer()

            if let totalNum = Double(total) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Tip Amount: ")
                            .padding(.top, 20)
                        Text("$\(totalNum * tipPercent * 0.01, specifier: "%0.2f")")
                            .padding(.top, 20)
                            .font(.headline.bold())
                    }

                    HStack {
                        Text("Total Amount: ")

                        Text("$\((totalNum + totalNum * tipPercent * 0.01), specifier: "%0.2f")")
                            .padding([.top, .bottom], 20)
                            .font(.headline.bold())
                    }
                    Spacer()
                }
            } else {
                VStack {
                    Text("First, please enter a sub-total amount.")
                        .padding([.top, .bottom], 20)
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .onAppear {
            #if DEBUG
            // Simulate tap gesture to focus on TextField only in live app, not in preview
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
            }
            #endif
        }
    }
}

// for custom numeric keyboard to disable decimal once typed
struct DecimalTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text("$")
                .foregroundColor(.black)
                .padding(.leading, 4) // Adjust the leading padding as needed

            UITextFieldWrapper(placeholder: placeholder, text: $text)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 2))
                .padding(.trailing, 4)
        }
        .padding(.trailing, 4) // Adjust the trailing padding as needed
    }
}


struct UITextFieldWrapper: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.borderStyle = .none // Remove default border style
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UITextFieldWrapper

        init(_ parent: UITextFieldWrapper) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let validCharacters = Set("0123456789.")
            let filtered = string.filter { validCharacters.contains($0) }

            // Allow only up to two decimal places
            if let currentText = textField.text, currentText.contains("."), string == "." {
                return false
            }

            // Allow only two digits after the decimal point
            if let rangeOfDot = textField.text?.range(of: "."), string != "" {
                let endIndex = rangeOfDot.upperBound
                if textField.text?.distance(from: endIndex, to: textField.text!.endIndex) == 2 {
                    return false
                }
            }

            // Limit the total number of characters to 16
            guard (textField.text?.count ?? 0) + string.count - range.length <= 16 else {
                return false
            }

            parent.text = (textField.text as NSString?)?.replacingCharacters(in: range, with: filtered) ?? ""
            return false
        }
    }
}

struct TipButton: View {
    var value: Int
    @Binding var tipPercent: Double

    var body: some View {
        Text("\(value)%")
            .padding()
            .foregroundColor(.white)
            .fontWeight(tipPercent == Double(value) ? .bold : .regular)
            .background(tipPercent == Double(value) ? Color.green : Color.blue)
            .cornerRadius(10)
            .onTapGesture {
                // Only update tipPercent if the button is not already selected
                if tipPercent != Double(value) {
                    tipPercent = Double(value)
                }
            }
            .overlay(
                tipPercent == Double(value) ?
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2) :
                    nil
            )
    }
}

// to help check if button is already pressed
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
