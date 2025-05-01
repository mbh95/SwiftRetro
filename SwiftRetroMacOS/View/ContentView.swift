import AppKit
import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch all systems, sorted by name
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \RetroSystem.systemName, ascending: true)
        ],
    )
    private var systems: FetchedResults<RetroSystem>

    @StateObject private var viewModel = GameViewModel()
    @State private var selectedSystem: RetroSystem?

    var body: some View {
        NavigationSplitView {
            List(systems, id: \.self, selection: $selectedSystem) {
                system in
                Text(system.systemName ?? "Unknown System")
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("Systems")

        } detail: {
            if let system = selectedSystem {
                VStack(alignment: .leading) {
                    Text(system.systemName ?? "Unknown System")
                        .font(.largeTitle)
                        .padding(.bottom, 5)

                    Text("Core Status: \(viewModel.coreStatus)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)

                    GameGridView(selectedSystem: system)
                        .onGameLaunch { game, system in
                            let firstCore =
                                (system.cores?.allObjects as? [RetroCore])?
                                .first

                            guard let corePath = firstCore?.corePath?.path()
                            else {
                                print(
                                    "No cores available for \(system.systemName ?? "Unknown System")"
                                )
                                return
                            }
                            print("LOADING")
                            print("CORE: %@", corePath)
                            print("GAME: %@", game.gamePath!.path())
                            viewModel.loadCore(
                                corePath: "mgba_libretro.dylib"
                            )
                            viewModel.loadGame(game: game)
                            viewModel.startCore()
                        }
                        .frame(maxHeight: .infinity)

                    Spacer()

                    if viewModel.isRunning {
                        GameView(viewModel: viewModel)
                            .frame(
                                width: CGFloat(viewModel.latestFrame.width),
                                height: CGFloat(viewModel.latestFrame.height)
                            )
                            .border(Color.gray)
                            .padding(.bottom)
                    }
                }
            } else {
                Text("Select a system from the list")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if selectedSystem == nil {
                selectedSystem = systems.first
            }
        }
        .focusable()
        .onKeyPress(phases: .down) { pressedKey in
            viewModel.handleKeyDown(key: pressedKey.key)
            return .handled
        }
        .onKeyPress(phases: .up) { pressedKey in
            viewModel.handleKeyUp(key: pressedKey.key)
            return .handled
        }
        .onChange(of: selectedSystem) { oldSystem, newSystem in
            print(
                "Selected System changed to: \(newSystem?.systemName ?? "None")"
            )
        }
    }
}

struct MacContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(
                \.managedObjectContext,
                CoreDataStack.shared.persistentContainer.viewContext
            )
    }
}

#Preview {
    ContentView()
        .environment(
            \.managedObjectContext,
            CoreDataStack.shared.persistentContainer.viewContext
        )
}
