import AppKit
import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openWindow) private var openWindow

    // Fetch all systems, sorted by name
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \RetroSystem.systemName, ascending: true)
        ],
    )
    private var systems: FetchedResults<RetroSystem>

    @EnvironmentObject var viewModel: GamePlayerModel
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
                            guard
                                let core =
                                    (system.cores?.allObjects as? [RetroCore])?
                                    .first
                            else {
                                print(
                                    "No cores available for \(system.systemName ?? "Unknown System")"
                                )
                                return
                            }

                            viewModel.unload()
                            guard viewModel.loadCore(coreToLoad: core),
                                viewModel.loadGame(gameToLoad: game)
                            else {
                                print("Failed to load core/game.")
                                return
                            }
                            
                            openWindow(id: "game-window")
                            viewModel.startCore()
                        }
                        .frame(maxHeight: .infinity)

                    Spacer()
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
