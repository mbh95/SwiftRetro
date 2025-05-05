//
//  GameGridView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/24/25.
//

import CoreData
import Foundation
import SwiftUI

struct GameGridView: View {

    var onGameLaunch: ((_: RetroGame, _: RetroSystem) -> Void)?

    let selectedSystem: RetroSystem
    @State public var selectedGame: RetroGame?

    @FetchRequest private var games: FetchedResults<RetroGame>

    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 20)
    ]

    init(selectedSystem: RetroSystem) {
        self.selectedSystem = selectedSystem
        self._games = FetchRequest<RetroGame>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \RetroGame.gameTitle, ascending: true)
            ],
            predicate: NSPredicate(format: "system == %@", selectedSystem),
            animation: .default
        )
    }

    func onGameLaunch(
        perform action: @escaping (_: RetroGame, _: RetroSystem) -> Void
    ) -> Self {
        var copy = self
        copy.onGameLaunch = action
        return copy
    }

    var body: some View {
        ScrollView {
            if games.isEmpty {
                Text(
                    "No games imported for \(selectedSystem.systemName ?? "this system") yet."
                )
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(games) { game in
                        GameGridItemView(
                            game: game,
                            isSelected: game == selectedGame,
                            parent: self
                        )
                        .gesture(
                            TapGesture(count: 2).onEnded {
                                guard let launchCallback = onGameLaunch else {
                                    return
                                }
                                launchCallback(game, selectedSystem)
                            }
                        )
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                selectedGame = game
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct GameGridItemView: View {
    @ObservedObject var game: RetroGame
    var isSelected: Bool
    var parent: GameGridView

    var body: some View {
        VStack {
            Image(systemName: "gamecontroller")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
                .foregroundColor(.blue)
                .padding(.bottom, 5)

            Text(game.gameTitle ?? "Untitled Game")
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(10)
        .background(
            isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
