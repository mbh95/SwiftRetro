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
    @State private var selectedSystem: RetroSystem?  // <-- State to track selected system

    func selectAndLoadCore() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Libretro Core (.dylib)"
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK,
            let coreUrl = openPanel.url
        else {
            return
        }

        viewModel.loadCore(corePath: coreUrl.path)
    }

    func selectAndLoadGame() {
        guard viewModel.coreIsLoaded else {
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Select Game File"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK,
            let gameUrl = openPanel.url
        else {
            return
        }

        viewModel.loadGame(gamePath: gameUrl.path)
    }

    var body: some View {
        NavigationSplitView {
            // --- Sidebar ---
            List(systems, id: \.self, selection: $selectedSystem) {
                system in
                Text(system.systemName ?? "Unknown System")
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)

        } detail: {
            VStack {
                Text("SwiftRetro for macOS")
                    .font(.headline)

                Text(selectedSystem?.systemName ?? "No System Selected")
                    .font(.title2)
                    .padding(.bottom)

                Text("Core Status: \(viewModel.coreStatus)")
                    .padding(.bottom)

                GameView(viewModel: viewModel)
                    .frame(
                        width: CGFloat(viewModel.latestFrame.width),
                        height: CGFloat(viewModel.latestFrame.height)
                    )
                    .border(Color.gray)

                HStack(spacing: 20) {
                    Button("Load Core") {
                        selectAndLoadCore()
                    }
                    .disabled(selectedSystem == nil)

                    Button("Load ROM") {
                        selectAndLoadGame()
                    }
                    .disabled(
                        viewModel.coreIsLoaded == false
                    )

                    Button("Unload") {
                        viewModel.unload()
                    }
                    .disabled(viewModel.coreIsLoaded == false)

                    Button("Start") {
                        viewModel.startCore()
                    }
                    .disabled(viewModel.canStart() == false)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 600)
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

// --- Previews (Keep as they are) ---
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
