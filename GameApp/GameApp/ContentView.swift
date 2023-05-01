//
//  ContentView.swift
//  GameApp
//
//  Created by admin on 4/10/23.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @StateObject var manager = GameManager(bounds: UIScreen.main.bounds)
    @State private var name: String = ""
    
    fileprivate func nameInput() -> some View {
        return ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Text("Welcome to Pinball")
                    .font(.custom("Menlo Bold", size: 36))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 42, trailing: 0))
                Text("Player name:")
                    .font(.custom("Menlo Regular", size: 24))
                    .foregroundColor(.white)
                TextField("Enter your name", text: $name)
                    .onChange(of: name){ _ in
                        manager.game.setName(name: name)
                    }
                    .textFieldStyle(.roundedBorder)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding()
                Button("START GAME", action: {
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        manager.showNameInput = false
                    }
                })
                .padding()
                .background(Color(red: 0, green: 1, blue: 0))
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .font(.custom("Menlo Bold", size: 18))
                Spacer()
            }
        }
    }
    
    var body: some View {
        ZStack {
            if manager.showNameInput {
                nameInput()
            } else {
                SpriteView(scene: manager.game)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .ignoresSafeArea()
                    .statusBarHidden(true)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
