import SwiftUI
import Foundation
import Observation

// MARK: - Codable Models

enum CoverColor: String, CaseIterable, Identifiable, Codable {
    case kraft = "Kraft Brown"
    case pitchBlack = "Pitch Black"
    case expeditionOrange = "Expedition Orange"
    case shenandoahPine = "Shenandoah Pine"
    case marineBlue = "Marine Blue"
    case cherryRed = "Cherry Red"

    var id: String { rawValue }

    var background: Color {
        switch self {
        case .kraft:
            return Color(red: 0.76, green: 0.63, blue: 0.46)
        case .pitchBlack:
            return Color(red: 0.15, green: 0.15, blue: 0.16)
        case .expeditionOrange:
            return Color(red: 0.89, green: 0.39, blue: 0.16)
        case .shenandoahPine:
            return Color(red: 0.22, green: 0.36, blue: 0.26)
        case .marineBlue:
            return Color(red: 0.18, green: 0.31, blue: 0.45)
        case .cherryRed:
            return Color(red: 0.69, green: 0.23, blue: 0.21)
        }
    }

    var textColor: Color {
        switch self {
        case .kraft, .expeditionOrange:
            return Color(red: 0.18, green: 0.14, blue: 0.10)
        case .pitchBlack, .shenandoahPine, .marineBlue, .cherryRed:
            return Color(red: 0.94, green: 0.91, blue: 0.85)
        }
    }

    var stapleColor: Color {
        switch self {
        case .pitchBlack:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        default:
            return Color(red: 0.60, green: 0.60, blue: 0.62)
        }
    }
}

enum PaperGridStyle: String, CaseIterable, Identifiable, Codable {
    case graph = "Graph Grid"
    case dotGrid = "Dot Grid"
    case ruled = "Ruled Lines"
    case blank = "Heavy Blank"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .graph: return "GRAPH"
        case .dotGrid: return "DOT GRID"
        case .ruled: return "RULED"
        case .blank: return "BLANK"
        }
    }

    var iconName: String {
        switch self {
        case .graph: return "grid"
        case .dotGrid: return "circle.grid.2x2"
        case .ruled: return "line.horizontal.3"
        case .blank: return "doc.plaintext"
        }
    }
}

struct CodablePoint: Codable, Equatable {
    var x: Double
    var y: Double

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }

    init(cgPoint: CGPoint) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
    }
}

struct SketchStroke: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var points: [CodablePoint]
    var colorHex: String
    var lineWidth: CGFloat
}

struct FieldChecklistItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var isDone: Bool
}

struct NotebookSpread: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var spreadIndex: Int
    var dateStamp: String
    var weatherStamp: String
    var locationStamp: String
    var checklist: [FieldChecklistItem]
    var memoText: String
    var sketchStrokes: [SketchStroke]
}

struct FieldNotebook: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var ownerName: String
    var projectName: String
    var coverColor: CoverColor
    var paperStyle: PaperGridStyle
    var dateStarted: String
    var practicalApplications: String
    var spreads: [NotebookSpread]
}

// MARK: - Persistence Store

@Observable
final class NotebookStore {
    var notebooks: [FieldNotebook] = []
    var selectedNotebookIndex: Int = 0

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("field_notes_library.json")
        load()
    }

    var currentNotebook: FieldNotebook? {
        guard !notebooks.isEmpty, notebooks.indices.contains(selectedNotebookIndex) else {
            return nil
        }
        return notebooks[selectedNotebookIndex]
    }

    func load() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                self.notebooks = try JSONDecoder().decode([FieldNotebook].self, from: data)
                if let firstIdx = self.notebooks.firstIndex(where: { $0.title == "FOLIO" }),
                   self.notebooks[firstIdx].spreads.count < 3 {
                    self.seedInitialData()
                }
            } else {
                seedInitialData()
            }
        } catch {
            seedInitialData()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(notebooks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Silently handle error
        }
    }

    func createNotebook(
        title: String,
        subtitle: String,
        owner: String,
        project: String,
        color: CoverColor,
        style: PaperGridStyle
    ) {
        let initialSpread = NotebookSpread(
            spreadIndex: 1,
            dateStamp: "OCT 15, 2026",
            weatherStamp: "62°F · OVERCAST",
            locationStamp: "CUPERTINO HQ",
            checklist: [
                FieldChecklistItem(text: "Unpack Field Notes memo book", isDone: true),
                FieldChecklistItem(text: "Record first field observation", isDone: false)
            ],
            memoText: "A fresh notebook waiting for field notes, napkin sketches, and bold expeditions.",
            sketchStrokes: []
        )

        let newBook = FieldNotebook(
            title: title.isEmpty ? "FOLIO" : title,
            subtitle: subtitle.isEmpty ? "DUO MEMO BOOK" : subtitle,
            ownerName: owner.isEmpty ? "EXPEDITION LEAD" : owner,
            projectName: project.isEmpty ? "EXPLORATION 01" : project,
            coverColor: color,
            paperStyle: style,
            dateStarted: "OCTOBER 15, 2026",
            practicalApplications: "01. Fleeting thoughts  02. Escape routes\n03. Dual-screen sketches  04. Coffee notes",
            spreads: [initialSpread]
        )

        notebooks.append(newBook)
        selectedNotebookIndex = notebooks.count - 1
        save()
    }

    func addSpreadToCurrentNotebook() {
        guard notebooks.indices.contains(selectedNotebookIndex) else { return }
        let nextIndex = notebooks[selectedNotebookIndex].spreads.count + 1
        let newSpread = NotebookSpread(
            spreadIndex: nextIndex,
            dateStamp: "OCT 15, 2026",
            weatherStamp: "65°F · FAIR",
            locationStamp: "WAYPOINT #\(nextIndex)",
            checklist: [
                FieldChecklistItem(text: "Record field reading", isDone: false)
            ],
            memoText: "Log entry for Spread #\(nextIndex)...",
            sketchStrokes: []
        )
        notebooks[selectedNotebookIndex].spreads.append(newSpread)
        save()
    }

    private func seedInitialData() {
        let spread1 = NotebookSpread(
            spreadIndex: 1,
            dateStamp: "OCT 15, 2026",
            weatherStamp: "62°F · OVERCAST",
            locationStamp: "CUPERTINO HQ",
            checklist: [
                FieldChecklistItem(text: "Calibrate dual-screen hinge", isDone: true),
                FieldChecklistItem(text: "Check compass & weather forecast", isDone: true),
                FieldChecklistItem(text: "Brew pour-over camp coffee", isDone: false),
                FieldChecklistItem(text: "Sketch folding notebook UI concepts", isDone: false)
            ],
            memoText: """
            DAY 01 — IPHONE DUO FIELD TESTING

            The dual displays fold neatly into the pocket like a classic 3-1/2" × 5-1/2" memo booklet.

            Initial thoughts:
            - Front cover screen handles immediate, fleeting thoughts.
            - Unfolding reveals the full two-page spread: checklist on the left, sketches & notes on the right.
            - Feels durable, tactile, and pleasantly quirky.
            """,
            sketchStrokes: []
        )

        let spread2 = NotebookSpread(
            spreadIndex: 2,
            dateStamp: "OCT 16, 2026",
            weatherStamp: "58°F · BRIGHT & CLEAR",
            locationStamp: "LAB BENCH 4",
            checklist: [
                FieldChecklistItem(text: "Measure page curl corner physics", isDone: true),
                FieldChecklistItem(text: "Inspect staple binding under magnification", isDone: true),
                FieldChecklistItem(text: "Test typewriter kerning", isDone: false)
            ],
            memoText: """
            DAY 02 — TACTILE INTERACTION TESTING

            Paper curling feels wonderfully responsive. When grabbing the dog-ear corner, the paper lifts diagonally, revealing the underlying sheet.

            Key observations:
            - Crease shadows give genuine depth.
            - Flipping back to previous spreads works naturally from the left corner.
            """,
            sketchStrokes: []
        )

        let spread3 = NotebookSpread(
            spreadIndex: 3,
            dateStamp: "OCT 17, 2026",
            weatherStamp: "64°F · SUNNY",
            locationStamp: "RIDGE TRAIL",
            checklist: [
                FieldChecklistItem(text: "Record GPS coordinates", isDone: false),
                FieldChecklistItem(text: "Draw trail elevation map", isDone: false)
            ],
            memoText: """
            DAY 03 — TRAIL NOTES

            Blank canvas ready for further observations and sketches.
            Pull the bottom corner to add new pages to this memo book.
            """,
            sketchStrokes: []
        )

        let initialBook = FieldNotebook(
            title: "FOLIO",
            subtitle: "DUO MEMO BOOK",
            ownerName: "J. HUDSON",
            projectName: "IPHONE DUO PROTOTYPE",
            coverColor: .kraft,
            paperStyle: .graph,
            dateStarted: "OCTOBER 15, 2026",
            practicalApplications: "01. Fleeting thoughts  02. Escape routes\n03. Dual-screen sketches  04. Coffee notes",
            spreads: [spread1, spread2, spread3]
        )

        let book2 = FieldNotebook(
            title: "EXPEDITION",
            subtitle: "TRAIL JOURNAL",
            ownerName: "J. HUDSON",
            projectName: "PACIFIC CREST TRAIL",
            coverColor: .expeditionOrange,
            paperStyle: .dotGrid,
            dateStarted: "OCTOBER 10, 2026",
            practicalApplications: "01. Trail waypoints  02. Weather log\n03. Campfire recipes  04. Star charts",
            spreads: [
                NotebookSpread(
                    spreadIndex: 1,
                    dateStamp: "OCT 10, 2026",
                    weatherStamp: "54°F · HIGH MOUNTAIN WIND",
                    locationStamp: "SECTION K MILE 128",
                    checklist: [
                        FieldChecklistItem(text: "Filter 3L stream water", isDone: true),
                        FieldChecklistItem(text: "Pitch tarp before dusk", isDone: true)
                    ],
                    memoText: "Sunset at 6,200ft. Wind picked up from the northwest. The orange cover is easy to find in the pack.",
                    sketchStrokes: []
                )
            ]
        )

        self.notebooks = [initialBook, book2]
        self.selectedNotebookIndex = 0
        save()
    }
}

// MARK: - Device Classification Helper

func isDuoAspectRatio(geometrySize: CGSize) -> Bool {
    let maxDim = max(geometrySize.width, geometrySize.height)
    let minDim = min(geometrySize.width, geometrySize.height)
    let ratio = maxDim / max(minDim, 1)
    return ratio < 1.6
}

func isDuoDevice(geometrySize: CGSize) -> Bool {
    #if targetEnvironment(simulator)
    if let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return model.contains("iPhone19,4")
    }
    #endif
    return isDuoAspectRatio(geometrySize: geometrySize)
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var store = NotebookStore()
    @State private var isOpen = false
    @State private var currentSpreadIndex = 0
    @State private var showShelf = false
    @State private var showCustomizer = false
    @State private var showNewBookSheet = false
    @State private var showPracticalGuide = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        GeometryReader { geometry in
            let isWideDisplay = geometry.size.width > 700

            ZStack {
                // Background surface
                Color(red: 0.12, green: 0.12, blue: 0.13)
                    .ignoresSafeArea()

                if let currentNotebook = store.currentNotebook {
                    if isOpen || isWideDisplay {
                        // Interior Two-Page Spread: Full Screen Edge-to-Edge
                        NotebookInteriorView(
                            notebook: currentNotebook,
                            currentSpreadIndex: $currentSpreadIndex,
                            isWideDisplay: isWideDisplay,
                            onUpdateSpread: { updatedSpread in
                                if store.notebooks.indices.contains(store.selectedNotebookIndex) {
                                    if let idx = store.notebooks[store.selectedNotebookIndex].spreads.firstIndex(where: { $0.id == updatedSpread.id }) {
                                        store.notebooks[store.selectedNotebookIndex].spreads[idx] = updatedSpread
                                        store.save()
                                    }
                                }
                            },
                            onAddSpread: {
                                store.addSpreadToCurrentNotebook()
                                currentSpreadIndex = (store.currentNotebook?.spreads.count ?? 1) - 1
                            },
                            onClose: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    isOpen = false
                                }
                            },
                            onOpenGuide: {
                                showPracticalGuide = true
                            },
                            onOpenShelf: {
                                showShelf = true
                            }
                        )
                        .ignoresSafeArea()
                        .transition(.opacity)
                    } else {
                        // Closed Front Cover: Full Screen Edge-to-Edge Pure Notebook Cover
                        NotebookCoverView(
                            notebook: currentNotebook,
                            shelfCount: store.notebooks.count,
                            onOpen: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    isOpen = true
                                }
                            },
                            onCustomize: {
                                showCustomizer = true
                            },
                            onOpenShelf: {
                                showShelf = true
                            },
                            onOpenGuide: {
                                showPracticalGuide = true
                            }
                        )
                        .ignoresSafeArea()
                        .transition(.opacity)
                    }
                }
            }
        }
        .sheet(isPresented: $showShelf) {
            NotebookShelfSheet(
                store: store,
                onSelectNotebook: { idx in
                    store.selectedNotebookIndex = idx
                    currentSpreadIndex = 0
                    showShelf = false
                },
                onAddNew: {
                    showShelf = false
                    showNewBookSheet = true
                }
            )
        }
        .sheet(isPresented: $showNewBookSheet) {
            NewNotebookSheet { title, subtitle, owner, project, color, style in
                store.createNotebook(title: title, subtitle: subtitle, owner: owner, project: project, color: color, style: style)
                currentSpreadIndex = 0
            }
        }
        .sheet(isPresented: $showCustomizer) {
            if store.notebooks.indices.contains(store.selectedNotebookIndex) {
                CoverCustomizerSheet(
                    notebook: $store.notebooks[store.selectedNotebookIndex],
                    onSave: {
                        store.save()
                    }
                )
            }
        }
        .sheet(isPresented: $showPracticalGuide) {
            FolioOnboardingSplashView(onStart: {
                hasSeenOnboarding = true
                showPracticalGuide = false
            })
        }
        .sheet(isPresented: $showOnboarding) {
            FolioOnboardingSplashView(onStart: {
                hasSeenOnboarding = true
                showOnboarding = false
            })
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
    }
}

// MARK: - Notebook Cover View (Full Screen, Pure Physical Notebook Front)

struct NotebookCoverView: View {
    let notebook: FieldNotebook
    let shelfCount: Int
    let onOpen: () -> Void
    let onCustomize: () -> Void
    let onOpenShelf: () -> Void
    let onOpenGuide: () -> Void

    var body: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let safeAreaTop = geo.safeAreaInsets.top
            let safeAreaBottom = geo.safeAreaInsets.bottom
            let isDuo = isDuoDevice(geometrySize: geo.size)

            ZStack {
                // 1. Heavy Cardstock Cover Base
                Rectangle()
                    .fill(notebook.coverColor.background)

                // 2. Subtle Cardstock Surface Lighting
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.clear,
                        Color.black.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 3. Right edge paper block reveal (interior 48 pages stratified leaf edge)
                HStack {
                    Spacer()
                    ZStack(alignment: .trailing) {
                        // Leaf block under-paper strip
                        Rectangle()
                            .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
                            .frame(width: 4)

                        // Delicate leaf stratification lines
                        VStack(spacing: 3) {
                            ForEach(0..<20) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.08))
                                    .frame(height: 1)
                            }
                        }
                        .frame(width: 4)

                        // Cover lip shadow cast onto the page edge
                        LinearGradient(
                            colors: [Color.black.opacity(0.22), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 2)
                    }
                }

                // 4. Left Spine Fold & Stitched Crease
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        // Deep spine roll gradient
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.38),
                                Color.black.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 32)

                        // Bound spine fold indentation line
                        Rectangle()
                            .fill(Color.black.opacity(0.22))
                            .frame(width: 1.5)
                            .padding(.leading, 18)

                        // 3 Authentic Bound Staples
                        VStack {
                            Spacer()
                            StapleView(color: notebook.coverColor.stapleColor)
                            Spacer()
                            StapleView(color: notebook.coverColor.stapleColor)
                            Spacer()
                            StapleView(color: notebook.coverColor.stapleColor)
                            Spacer()
                        }
                        .padding(.leading, 8)
                    }
                    Spacer()
                }

                // 5. Stamped Cover Layout
                VStack(spacing: 0) {
                    // Header Bar: 3 Uniform Stamped Buttons with Rectangular Box & Curved Corners like Cover Letter (No system pill, left-shifted)
                    let cameraRowTopPadding: CGFloat = isDuo
                        ? (safeAreaTop > 0 ? max(30.0, (safeAreaTop - 26) / 2 + 18) : 30.0)
                        : max(safeAreaTop + 36, 78.0)

                    HStack(spacing: 8) {
                        // 1. 3-Pack Shelf Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpenShelf()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 10))
                                Text("3-PACK")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.88))
                            .frame(width: 80, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(notebook.coverColor.textColor.opacity(0.4), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)

                        // 2. Practical Guide Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpenGuide()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                                Text("GUIDE")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.88))
                            .frame(width: 80, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(notebook.coverColor.textColor.opacity(0.4), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)

                        // 3. Cover Customizer Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onCustomize()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 10))
                                Text("CUSTOMIZE")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.88))
                            .frame(width: 84, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(notebook.coverColor.textColor.opacity(0.4), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.leading, isDuo ? 30 : 20)
                    .padding(.trailing, 18)
                    .padding(.top, cameraRowTopPadding)

                    Spacer(minLength: 16)

                    // Debossed Main Title & Subtitle
                    VStack(spacing: 6) {
                        Text(notebook.title.uppercased())
                            .font(.system(size: min(44, totalW * 0.11), weight: .black, design: .default))
                            .tracking(4)
                            .foregroundColor(notebook.coverColor.textColor)
                            .shadow(color: .white.opacity(0.12), radius: 0, x: 0, y: 1)

                        Text(notebook.subtitle.uppercased())
                            .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                            .tracking(2.5)
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.82))

                        // Vintage rule ornament
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(notebook.coverColor.textColor.opacity(0.35))
                                .frame(height: 1)
                            Circle()
                                .fill(notebook.coverColor.textColor.opacity(0.6))
                                .frame(width: 4, height: 4)
                            Rectangle()
                                .fill(notebook.coverColor.textColor.opacity(0.35))
                                .frame(height: 1)
                        }
                        .frame(maxWidth: 160)
                        .padding(.top, 4)
                    }
                    .padding(.leading, 24)
                    .padding(.trailing, 16)

                    Spacer(minLength: 20)

                    // Debossed Specifications Box
                    VStack(alignment: .leading, spacing: 10) {
                        specRow(label: "PROJECT", value: notebook.projectName)
                        Divider().background(notebook.coverColor.textColor.opacity(0.28))
                        specRow(label: "RECORDED BY", value: notebook.ownerName)
                        Divider().background(notebook.coverColor.textColor.opacity(0.28))
                        specRow(label: "STARTED", value: notebook.dateStarted)
                        Divider().background(notebook.coverColor.textColor.opacity(0.28))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PRACTICAL APPLICATIONS:")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(notebook.coverColor.textColor.opacity(0.75))
                            Text(notebook.practicalApplications)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(notebook.coverColor.textColor.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(notebook.coverColor.textColor.opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.leading, isDuo ? 32 : 24)
                    .padding(.trailing, isDuo ? 22 : 20)

                    Spacer(minLength: 20)

                    // Bottom Manufacturer Stamped Certification & Tactile Open Cue
                    VStack(spacing: 8) {
                        Text("48 PAGES · 3-1/2″ × 5-1/2″ · \(notebook.paperStyle.rawValue.uppercased())")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.8))

                        Text("FOLIO NOTEBOOK CO. · CUPERTINO & CHICAGO · U.S.A.")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.65))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("DURABLE WATER-RESISTANT COVER · BOUND WITH PRIDE")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.5))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(.leading, isDuo ? 24 : 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, max(24, safeAreaBottom + 14))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        if value.translation.width < -40 || value.predictedEndTranslation.width < -70 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onOpen()
                        }
                    }
            )
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onOpen()
            }
        }
    }

    private func specRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(label):")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(notebook.coverColor.textColor.opacity(0.7))
            Spacer()
            Text(value.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(notebook.coverColor.textColor)
                .lineLimit(1)
        }
    }
}

// MARK: - Staple Component

struct StapleView: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.3))
                .frame(width: 5, height: 28)
                .offset(x: 0.5, y: 1)

            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.7),
                            Color.white.opacity(0.8),
                            color.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4, height: 26)
        }
    }
}

// MARK: - Folio Onboarding Splash & Field Guide

struct FolioOnboardingSplashView: View {
    @Environment(\.dismiss) private var dismiss
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Field Guide Vintage Top Header Bar
            HStack {
                Text("FIELD MANUAL · USER GUIDE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))

                Spacer()

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                }) {
                    Text("DISMISS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(red: 0.45, green: 0.40, blue: 0.35).opacity(0.4), lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 22) {
                    // Header Stamped Badge & Title
                    VStack(spacing: 8) {
                        Text("FOLIO FIELD MANUAL · NO. 01")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2.0)
                            .foregroundColor(Color(red: 0.88, green: 0.45, blue: 0.18))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.88, green: 0.45, blue: 0.18).opacity(0.12))
                            .cornerRadius(4)

                        Text("WELCOME TO FOLIO")
                            .font(.system(size: 23, weight: .black, design: .default))
                            .foregroundColor(Color(red: 0.20, green: 0.18, blue: 0.16))

                        Text("The Dual-Screen Pocket Notebook")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                    }
                    .padding(.top, 16)

                    // Hints list
                    VStack(spacing: 12) {
                        onboardingCard(
                            num: "01",
                            icon: "hand.draw.fill",
                            title: "NATURAL PAGE CURLING",
                            desc: "Grab either bottom corner to curl and peel the page like real Finch 70# paper, or swipe across the spread to flip."
                        )

                        onboardingCard(
                            num: "02",
                            icon: "rectangle.split.2x1.fill",
                            title: "ADAPTIVE DUO POSES",
                            desc: "Open flat for the 2-page spread with the spine centered on the crease. Close to focus on a full single pocket page."
                        )

                        onboardingCard(
                            num: "03",
                            icon: "pencil.and.scribble",
                            title: "CHECKLISTS & FIELD SKETCHES",
                            desc: "Log tasks and timestamps on the left page. On the right, toggle between typewriter notes and Apple Pencil sketches."
                        )

                        onboardingCard(
                            num: "04",
                            icon: "books.vertical.fill",
                            title: "3-PACK SHELF & CUSTOM COVERS",
                            desc: "Tap '3-PACK' anytime to create new notebooks, customize cardstock covers, and pick graph, lined, or dot paper."
                        )
                    }

                    // Field Rules & Practical Conversions Disclosure
                    DisclosureGroup("FIELD RULES & PRACTICAL CONVERSIONS") {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HANDY CONVERSIONS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.30, green: 0.25, blue: 0.20))
                                Text("• 1 Inch = 25.4 mm = 72 pt\n• 1 Meter = 39.37 Inches = 3.28 Feet\n• 1 Knot = 1.15 MPH = 1.85 km/h\n• Boiling Point = 212°F = 100°C")
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("EMERGENCY MORSE CODE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.30, green: 0.25, blue: 0.20))
                                Text("• S.O.S. = · · ·  — — —  · · ·\n• YES = — · — —  ·  · · ·\n• NO = — ·  — — —")
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("GOLDEN RULES FOR NOTE TAKING")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.30, green: 0.25, blue: 0.20))
                                Text("1. Write down ideas immediately before they evaporate.\n2. Don't worry about messy handwriting.\n3. A notebook in your pocket is worth ten in a drawer.\n4. Fold the Duo when walking, unfold when inspiration strikes.")
                                    .font(.system(size: 10.5, design: .serif))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.65))
                    )

                    // Start Exploring Button (Rectangle box with curved corners like cover letter)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onStart()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Text("START EXPLORING")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1.5)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.88, green: 0.45, blue: 0.18))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.88, green: 0.45, blue: 0.18), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .padding(20)
            }
        }
        .background(Color(red: 0.965, green: 0.950, blue: 0.920).ignoresSafeArea())
    }

    private func onboardingCard(num: String, icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.88, green: 0.45, blue: 0.18).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.88, green: 0.45, blue: 0.18))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(num)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(Color(red: 0.88, green: 0.45, blue: 0.18))
                    Text(title)
                        .font(.system(size: 11.5, weight: .black, design: .monospaced))
                        .foregroundColor(Color(red: 0.22, green: 0.20, blue: 0.18))
                }
                Text(desc)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(Color(red: 0.38, green: 0.35, blue: 0.32))
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.90))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Single Spread Page (Individual Left or Right Page)

enum RightPageMode {
    case memo
    case sketch
}

struct SingleSpreadPageView: View {
    let notebook: FieldNotebook
    let spread: NotebookSpread
    let isLeft: Bool
    let isWideDisplay: Bool
    let spreadCount: Int
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
    var isDuo: Bool = false
    let onUpdateSpread: (NotebookSpread) -> Void
    let onOpenGuide: () -> Void
    let onOpenShelf: () -> Void
    let onClose: () -> Void

    @State private var newChecklistText: String = ""
    @State private var rightPageMode: RightPageMode = .memo
    @State private var currentDrawingPoints: [CGPoint] = []

    var body: some View {
        ZStack {
            // Page stack stratification layers under the leaf (outer edge depth)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.88, green: 0.85, blue: 0.80))
                .offset(x: isLeft ? -2.5 : 2.5, y: 1.5)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.92, green: 0.90, blue: 0.86))
                .offset(x: isLeft ? -1.2 : 1.2, y: 0.8)

            // Heavyweight Finch 70# Finch Opaque warm paper base
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.985, green: 0.972, blue: 0.938),
                            Color(red: 0.965, green: 0.950, blue: 0.915)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Grid / Dot / Ruled background overlay
            PaperPatternView(style: notebook.paperStyle)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Adaptive top padding: elevated for Duo, safe-area clear for Dynamic Island / notch iPhones
            let pageTopPadding: CGFloat = isDuo
                ? (safeAreaTop > 0 ? max(22.0, (safeAreaTop - 24) / 2 + 12) : 22.0)
                : max(safeAreaTop + 36, 72.0)

            if isLeft {
                leftPageContent
                    .padding(.top, pageTopPadding)
                    .padding(.bottom, max(14, safeAreaBottom + 4))
                    .padding(.leading, isWideDisplay ? 20 : (isDuo ? 16 : 14))
                    .padding(.trailing, isWideDisplay ? 16 : (isDuo ? 16 : 14))
            } else {
                rightPageContent
                    .padding(.top, pageTopPadding)
                    .padding(.bottom, max(14, safeAreaBottom + 4))
                    .padding(.leading, isWideDisplay ? 16 : (isDuo ? 16 : 14))
                    .padding(.trailing, isWideDisplay ? 20 : (isDuo ? 16 : 14))
            }
        }
        .overlay(
            // Crisp paper bevel highlight & subtle edge border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color(red: 0.80, green: 0.76, blue: 0.70).opacity(0.65),
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    private var leftPageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Left page header (Buttons safely grouped on left/center away from camera/clock)
            HStack(alignment: .center, spacing: isWideDisplay ? 8 : 6) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenShelf()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 10))
                        Text("3-PACK")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.4), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text("FIELD OBSERVATIONS")
                        .font(.system(size: isWideDisplay ? 12 : 11, weight: .black, design: .default))
                        .tracking(1.0)
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.18))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(spread.dateStamp) · \(spread.weatherStamp)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenGuide()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("GUIDE")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.4), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)

                if !isWideDisplay {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onClose()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 10))
                            Text("FOLD")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.4), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Checklist section
            Text("EXPEDITION CHECKLIST:")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(spread.checklist) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Button(action: {
                                var updated = spread
                                if let idx = updated.checklist.firstIndex(where: { $0.id == item.id }) {
                                    updated.checklist[idx].isDone.toggle()
                                    onUpdateSpread(updated)
                                }
                            }) {
                                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(item.isDone ? Color.orange : Color(red: 0.4, green: 0.35, blue: 0.3))
                            }
                            .buttonStyle(.plain)

                            Text(item.text)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .strikethrough(item.isDone, color: .gray)
                                .foregroundColor(item.isDone ? .gray : Color(red: 0.2, green: 0.18, blue: 0.15))

                            Spacer()
                        }
                    }
                }
            }

            // Add checklist item field
            HStack(spacing: 8) {
                TextField("Add task or reading...", text: $newChecklistText)
                    .font(.system(size: 11, design: .serif))
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color.black.opacity(0.04))
                    .cornerRadius(4)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    guard !newChecklistText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    var updated = spread
                    updated.checklist.append(FieldChecklistItem(text: newChecklistText, isDone: false))
                    onUpdateSpread(updated)
                    newChecklistText = ""
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text("ADD")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.4), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Left page footer
            HStack(alignment: .bottom) {
                Text("PAGE \(String(format: "%02d", (spread.spreadIndex * 2) - 1))")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.gray.opacity(0.8))
                    .padding(.bottom, 2)

                Spacer()
            }
        }
    }

    private var rightPageContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Right page header (Buttons safely grouped on left/center away from persistent clock and camera)
            HStack(alignment: .center, spacing: isWideDisplay ? 8 : 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rightPageMode == .memo ? "MEMO & LOG BOOK" : "FIELD SKETCH")
                        .font(.system(size: isWideDisplay ? 12 : 11, weight: .black, design: .default))
                        .tracking(1.0)
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.18))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("LOC: \(spread.locationStamp)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                // Mode Toggle: Box Style with Curved Corners (Replaced liquid glass toggle)
                HStack(spacing: 3) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        rightPageMode = .memo
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 9))
                            Text("MEMO")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(rightPageMode == .memo ? Color(red: 0.25, green: 0.22, blue: 0.18) : Color(red: 0.55, green: 0.50, blue: 0.45))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    rightPageMode == .memo ? Color(red: 0.25, green: 0.22, blue: 0.18).opacity(0.8) : Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.25),
                                    lineWidth: rightPageMode == .memo ? 1.4 : 1.0
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        rightPageMode = .sketch
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil.and.scribble")
                                .font(.system(size: 9))
                            Text("SKETCH")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(rightPageMode == .sketch ? Color(red: 0.25, green: 0.22, blue: 0.18) : Color(red: 0.55, green: 0.50, blue: 0.45))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    rightPageMode == .sketch ? Color(red: 0.25, green: 0.22, blue: 0.18).opacity(0.8) : Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.25),
                                    lineWidth: rightPageMode == .sketch ? 1.4 : 1.0
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                if rightPageMode == .sketch {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        var updated = spread
                        updated.sketchStrokes.removeAll()
                        onUpdateSpread(updated)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("CLEAR")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.red.opacity(0.45), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                if !isWideDisplay {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onClose()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 10))
                            Text("FOLD")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.4), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            if rightPageMode == .memo {
                TextEditor(text: Binding(
                    get: { spread.memoText },
                    set: { newText in
                        var updated = spread
                        updated.memoText = newText
                        onUpdateSpread(updated)
                    }
                ))
                .font(.system(size: 12, design: .serif))
                .foregroundColor(Color(red: 0.2, green: 0.18, blue: 0.15))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .lineSpacing(6)
            } else {
                SketchDrawingCanvas(
                    strokes: spread.sketchStrokes,
                    currentPoints: currentDrawingPoints
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.02))
                .cornerRadius(6)
                .gesture(
                    DragGesture(minimumDistance: 0.1)
                        .onChanged { value in
                            currentDrawingPoints.append(value.location)
                        }
                        .onEnded { _ in
                            if !currentDrawingPoints.isEmpty {
                                var updated = spread
                                let newStroke = SketchStroke(
                                    points: currentDrawingPoints.map { CodablePoint(cgPoint: $0) },
                                    colorHex: "#2A2A2A",
                                    lineWidth: 2.0
                                )
                                updated.sketchStrokes.append(newStroke)
                                onUpdateSpread(updated)
                                currentDrawingPoints = []
                            }
                        }
                )
            }

            Spacer()

            // Right page footer
            HStack(alignment: .bottom) {
                Spacer()
                Text("SPREAD \(spread.spreadIndex) OF \(spreadCount) · PAGE \(String(format: "%02d", spread.spreadIndex * 2))")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.gray.opacity(0.8))
                    .padding(.bottom, 2)
            }
        }
    }
}

// MARK: - Notebook Interior (Two-Page Spread with Physical Page Curl)

// MARK: - Kindle Page Curl Geometry & Physics

struct KindleCurlGeometry2D {
    struct CurlState {
        let cornerBottom: CGPoint
        let cornerTop: CGPoint?
        let creaseBottom: CGPoint
        let creaseTopSide: CGPoint
        let creaseHitsSide: Bool
        let ctrlBottom: CGPoint
        let ctrlSide: CGPoint
        let liftHeight: CGFloat
        let progress: CGFloat
    }

    static func calculate(
        corner: CGPoint,
        restCorner: CGPoint,
        totalSize: CGSize,
        isFromRight: Bool
    ) -> CurlState {
        let totalW = totalSize.width
        let totalH = totalSize.height

        let xc = corner.x
        let yc = corner.y
        let restX = restCorner.x
        let restY = restCorner.y

        let liftHeight = max(0.0, totalH - yc)
        let midX = (restX + xc) / 2.0
        let midY = (restY + yc) / 2.0

        var vx = xc - restX
        var vy = yc - restY

        if abs(vx) < 1e-4 { vx = isFromRight ? -1e-4 : 1e-4 }
        if abs(vy) < 1e-4 { vy = -1e-4 }

        // Crease line intersection with bottom edge y = totalH
        let xb = min(totalW, max(0.0, midX - (totalH - midY) * (vy / vx)))
        let pBottom = CGPoint(x: xb, y: totalH)

        // Crease line intersection with outer side or top edge
        var pTopSide: CGPoint
        let creaseHitsSide: Bool
        if isFromRight {
            let yr = midY - (totalW - midX) * (vx / vy)
            if yr >= 0.0 && yr <= totalH {
                creaseHitsSide = true
                pTopSide = CGPoint(x: totalW, y: yr)
            } else {
                creaseHitsSide = false
                let xt = midX + midY * (vy / vx)
                pTopSide = CGPoint(x: min(totalW, max(0.0, xt)), y: 0.0)
            }
        } else {
            let yl = midY - (0.0 - midX) * (vx / vy)
            if yl >= 0.0 && yl <= totalH {
                creaseHitsSide = true
                pTopSide = CGPoint(x: 0.0, y: yl)
            } else {
                creaseHitsSide = false
                let xt = midX + midY * (vy / vx)
                pTopSide = CGPoint(x: min(totalW, max(0.0, xt)), y: 0.0)
            }
        }

        // Lifted bottom edge control point (organic paper curve bowing downward)
        let ctrlBottomX = (xb + xc) / 2.0 + (isFromRight ? 12.0 : -12.0)
        let ctrlBottomY = (totalH + yc) / 2.0 + min(26.0, liftHeight * 0.22)
        let ctrlBottom = CGPoint(x: ctrlBottomX, y: ctrlBottomY)

        // Reflected top corner when crease line exits through the top edge
        var cornerTop: CGPoint? = nil
        if !creaseHitsSide {
            let restTop = CGPoint(x: isFromRight ? totalW : 0.0, y: 0.0)
            let a = pTopSide.y - pBottom.y
            let b = -(pTopSide.x - pBottom.x)
            let c = (pTopSide.x - pBottom.x) * pBottom.y - (pTopSide.y - pBottom.y) * pBottom.x
            let denom = a * a + b * b
            if denom > 1e-4 {
                let d = (a * restTop.x + b * restTop.y + c) / denom
                cornerTop = CGPoint(x: restTop.x - 2 * a * d, y: restTop.y - 2 * b * d)
            }
        }

        // Lifted outer side control point
        let targetOuter = cornerTop ?? pTopSide
        let ctrlSideX = (targetOuter.x + xc) / 2.0 + (isFromRight ? 8.0 : -8.0)
        let ctrlSideY = (targetOuter.y + yc) / 2.0
        let ctrlSide = CGPoint(x: ctrlSideX, y: ctrlSideY)

        let totalTravel = totalW
        let currentDist = isFromRight ? (totalW - xc) : xc
        let progress = max(0.0, min(1.0, currentDist / totalTravel))

        return CurlState(
            cornerBottom: corner,
            cornerTop: cornerTop,
            creaseBottom: pBottom,
            creaseTopSide: pTopSide,
            creaseHitsSide: creaseHitsSide,
            ctrlBottom: ctrlBottom,
            ctrlSide: ctrlSide,
            liftHeight: liftHeight,
            progress: progress
        )
    }
}

// MARK: - Notebook Interior (Two-Page Spread with Interactive 2D Page Turn)

struct NotebookInteriorView: View {
    let notebook: FieldNotebook
    @Binding var currentSpreadIndex: Int
    let isWideDisplay: Bool
    let onUpdateSpread: (NotebookSpread) -> Void
    let onAddSpread: () -> Void
    let onClose: () -> Void
    let onOpenGuide: () -> Void
    let onOpenShelf: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var isFromRight: Bool = true
    @State private var isAnimatingTurn: Bool = false
    @State private var turnProgress: CGFloat = 0.0
    @State private var singlePageIndex: Int = 0

    var totalSinglePages: Int {
        max(1, notebook.spreads.count * 2)
    }

    private func singlePageView(for index: Int, safeAreaTop: CGFloat, safeAreaBottom: CGFloat, isDuo: Bool) -> some View {
        let spreadIdx = max(0, min(notebook.spreads.count - 1, index / 2))
        let isLeft = (index % 2 == 0)
        let spread = notebook.spreads[spreadIdx]

        return SingleSpreadPageView(
            notebook: notebook,
            spread: spread,
            isLeft: isLeft,
            isWideDisplay: isWideDisplay,
            spreadCount: notebook.spreads.count,
            safeAreaTop: safeAreaTop,
            safeAreaBottom: safeAreaBottom,
            isDuo: isDuo,
            onUpdateSpread: onUpdateSpread,
            onOpenGuide: onOpenGuide,
            onOpenShelf: onOpenShelf,
            onClose: onClose
        )
    }

    var currentSpread: NotebookSpread {
        if notebook.spreads.indices.contains(currentSpreadIndex) {
            return notebook.spreads[currentSpreadIndex]
        }
        return notebook.spreads.first ?? NotebookSpread(
            spreadIndex: 1,
            dateStamp: "OCT 15, 2026",
            weatherStamp: "62°F",
            locationStamp: "BASE",
            checklist: [],
            memoText: "",
            sketchStrokes: []
        )
    }

    var nextSpread: NotebookSpread {
        if currentSpreadIndex + 1 < notebook.spreads.count {
            return notebook.spreads[currentSpreadIndex + 1]
        }
        return NotebookSpread(
            spreadIndex: notebook.spreads.count + 1,
            dateStamp: "OCT 16, 2026",
            weatherStamp: "65°F · FAIR",
            locationStamp: "WAYPOINT #\(notebook.spreads.count + 1)",
            checklist: [
                FieldChecklistItem(text: "Record field reading", isDone: false),
                FieldChecklistItem(text: "Check weather barometer", isDone: false)
            ],
            memoText: "Log entry for Spread #\(notebook.spreads.count + 1)...",
            sketchStrokes: []
        )
    }

    var prevSpread: NotebookSpread {
        if currentSpreadIndex > 0 {
            return notebook.spreads[currentSpreadIndex - 1]
        }
        return currentSpread
    }

    var body: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let totalH = geo.size.height
            let halfW = totalW / 2.0
            let pageW = isWideDisplay ? halfW : totalW
            let safeAreaTop = geo.safeAreaInsets.top
            let safeAreaBottom = max(geo.safeAreaInsets.bottom, 24.0)
            let isDuo = isDuoDevice(geometrySize: geo.size)

            let restCorner = CGPoint(x: isFromRight ? totalW : 0.0, y: totalH)
            let cornerPoint: CGPoint = {
                if isDragging {
                    let maxSweep = totalW * 1.05
                    let rawDx = dragOffset.width
                    let rawDy = dragOffset.height

                    let dx = isFromRight ? max(-maxSweep, min(15.0, rawDx)) : min(maxSweep, max(-15.0, rawDx))
                    let dy = max(-totalH * 0.75, min(15.0, rawDy))

                    return CGPoint(x: restCorner.x + dx, y: restCorner.y + dy)
                } else if turnProgress > 0.0 {
                    let t = turnProgress
                    let arcLift = -sin(t * .pi) * min(160.0, totalH * 0.28)
                    let xc = isFromRight ? (totalW - totalW * t) : (totalW * t)
                    let yc = totalH + arcLift
                    return CGPoint(x: xc, y: yc)
                } else {
                    return restCorner
                }
            }()

            let curl = KindleCurlGeometry2D.calculate(
                corner: cornerPoint,
                restCorner: restCorner,
                totalSize: geo.size,
                isFromRight: isFromRight
            )

            let isTurnActive = isDragging || turnProgress > 0.001

            ZStack {
                // Layer 1: Underneath Target Spread / Page
                if isTurnActive {
                    if isWideDisplay {
                        let targetSpread = isFromRight ? nextSpread : prevSpread
                        HStack(spacing: 0) {
                            SingleSpreadPageView(
                                notebook: notebook,
                                spread: targetSpread,
                                isLeft: true,
                                isWideDisplay: isWideDisplay,
                                spreadCount: notebook.spreads.count,
                                safeAreaTop: safeAreaTop,
                                safeAreaBottom: safeAreaBottom,
                                isDuo: isDuo,
                                onUpdateSpread: onUpdateSpread,
                                onOpenGuide: onOpenGuide,
                                onOpenShelf: onOpenShelf,
                                onClose: onClose
                            )
                            .frame(width: pageW, height: totalH)

                            SingleSpreadPageView(
                                notebook: notebook,
                                spread: targetSpread,
                                isLeft: false,
                                isWideDisplay: isWideDisplay,
                                spreadCount: notebook.spreads.count,
                                safeAreaTop: safeAreaTop,
                                safeAreaBottom: safeAreaBottom,
                                isDuo: isDuo,
                                onUpdateSpread: onUpdateSpread,
                                onOpenGuide: onOpenGuide,
                                onOpenShelf: onOpenShelf,
                                onClose: onClose
                            )
                            .frame(width: pageW, height: totalH)
                        }
                    } else {
                        if isFromRight {
                            let nextIdx = min(totalSinglePages - 1, singlePageIndex + 1)
                            singlePageView(
                                for: nextIdx,
                                safeAreaTop: safeAreaTop,
                                safeAreaBottom: safeAreaBottom,
                                isDuo: isDuo
                            )
                            .frame(width: totalW, height: totalH)
                        } else {
                            let prevIdx = max(0, singlePageIndex - 1)
                            singlePageView(
                                for: prevIdx,
                                safeAreaTop: safeAreaTop,
                                safeAreaBottom: safeAreaBottom,
                                isDuo: isDuo
                            )
                            .frame(width: totalW, height: totalH)
                        }
                    }
                }

                // Layer 2: Current Spread / Single Page with Dynamic 2D Crease Cutaway Mask
                Group {
                    if isWideDisplay {
                        HStack(spacing: 0) {
                            SingleSpreadPageView(
                                notebook: notebook,
                                spread: currentSpread,
                                isLeft: true,
                                isWideDisplay: isWideDisplay,
                                spreadCount: notebook.spreads.count,
                                safeAreaTop: safeAreaTop,
                                safeAreaBottom: safeAreaBottom,
                                isDuo: isDuo,
                                onUpdateSpread: onUpdateSpread,
                                onOpenGuide: onOpenGuide,
                                onOpenShelf: onOpenShelf,
                                onClose: onClose
                            )
                            .frame(width: pageW, height: totalH)

                            SingleSpreadPageView(
                                notebook: notebook,
                                spread: currentSpread,
                                isLeft: false,
                                isWideDisplay: isWideDisplay,
                                spreadCount: notebook.spreads.count,
                                safeAreaTop: safeAreaTop,
                                safeAreaBottom: safeAreaBottom,
                                isDuo: isDuo,
                                onUpdateSpread: onUpdateSpread,
                                onOpenGuide: onOpenGuide,
                                onOpenShelf: onOpenShelf,
                                onClose: onClose
                            )
                            .frame(width: pageW, height: totalH)
                        }
                    } else {
                        singlePageView(
                            for: singlePageIndex,
                            safeAreaTop: safeAreaTop,
                            safeAreaBottom: safeAreaBottom,
                            isDuo: isDuo
                        )
                        .frame(width: totalW, height: totalH)
                    }
                }
                .mask(
                    Group {
                        if isTurnActive {
                            Path { path in
                                let pb = curl.creaseBottom
                                let pts = curl.creaseTopSide
                                if isFromRight {
                                    if curl.creaseHitsSide {
                                        // Crease exits side: keep entire top of sheet, only cut out folded corner
                                        path.move(to: CGPoint(x: -20, y: -20))
                                        path.addLine(to: CGPoint(x: totalW + 20, y: -20))
                                        path.addLine(to: CGPoint(x: totalW + 20, y: pts.y))
                                        path.addLine(to: CGPoint(x: pb.x, y: totalH + 20))
                                        path.addLine(to: CGPoint(x: -20, y: totalH + 20))
                                        path.closeSubpath()
                                    } else {
                                        // Crease exits top: cut along full crease line
                                        path.move(to: CGPoint(x: -20, y: -20))
                                        path.addLine(to: CGPoint(x: pts.x, y: -20))
                                        path.addLine(to: CGPoint(x: pb.x, y: totalH + 20))
                                        path.addLine(to: CGPoint(x: -20, y: totalH + 20))
                                        path.closeSubpath()
                                    }
                                } else {
                                    if curl.creaseHitsSide {
                                        // Crease exits left edge: keep entire top of sheet
                                        path.move(to: CGPoint(x: pts.x, y: pts.y))
                                        path.addLine(to: CGPoint(x: -20, y: -20))
                                        path.addLine(to: CGPoint(x: totalW + 20, y: -20))
                                        path.addLine(to: CGPoint(x: totalW + 20, y: totalH + 20))
                                        path.addLine(to: CGPoint(x: pb.x, y: totalH + 20))
                                        path.closeSubpath()
                                    } else {
                                        // Crease exits top: cut along full crease line
                                        path.move(to: CGPoint(x: pts.x, y: -20))
                                        path.addLine(to: CGPoint(x: totalW + 20, y: -20))
                                        path.addLine(to: CGPoint(x: totalW + 20, y: totalH + 20))
                                        path.addLine(to: CGPoint(x: pb.x, y: totalH + 20))
                                        path.closeSubpath()
                                    }
                                }
                            }
                        } else {
                            Rectangle()
                        }
                    }
                )

                // Layer 3: Solid Opaque Finch 70# Paper Flap with Grid, 3D Caliper Bevel & Shadows
                if isTurnActive && (curl.liftHeight > 0.5 || curl.progress > 0.005) {
                    KindlePageCurlCanvas2D(
                        state: curl,
                        isFromRight: isFromRight,
                        totalSize: geo.size
                    )
                }

                // Layer 4: Center Spine ALIGNED WITH CREASE (Dual-screen wide mode only)
                if isWideDisplay {
                    centerSpineView
                        .frame(width: 20, height: totalH)
                        .position(x: halfW, y: totalH / 2.0)
                        .allowsHitTesting(false)
                }

                // Layer 5: Interactive 2D Corner & Edge Drag Zones
                HStack(spacing: 0) {
                    // Left Edge & Corner Turn Strip
                    let canGoBack = isWideDisplay ? (currentSpreadIndex > 0) : true
                    if canGoBack {
                        Color.clear
                            .frame(width: 76)
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 4)
                                    .onChanged { value in
                                        guard !isAnimatingTurn else { return }
                                        if !isDragging {
                                            isDragging = true
                                            isFromRight = false
                                            UISelectionFeedbackGenerator().selectionChanged()
                                        }
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        guard !isAnimatingTurn else { return }
                                        let dx = value.translation.width
                                        let predictedDx = value.predictedEndTranslation.width
                                        let threshold = totalW * 0.32
                                        if dx > threshold || predictedDx > threshold * 1.3 {
                                            completePageTurn2D(forward: false, currentTravel: dx, totalW: totalW)
                                        } else {
                                            cancelPageTurn2D()
                                        }
                                    }
                            )
                            .onTapGesture {
                                startTapPageTurn(forward: false)
                            }
                    } else {
                        Color.clear.frame(width: 76)
                    }

                    // Center bottom margin swipe zone
                    VStack(spacing: 0) {
                        Spacer()
                        Color.clear
                            .frame(height: max(60, safeAreaBottom + 16))
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 4)
                                    .onChanged { value in
                                        guard !isAnimatingTurn else { return }
                                        if !isDragging {
                                            isDragging = true
                                            isFromRight = (value.startLocation.x > totalW * 0.5)
                                            UISelectionFeedbackGenerator().selectionChanged()
                                        }
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        guard !isAnimatingTurn else { return }
                                        let dx = isFromRight ? -value.translation.width : value.translation.width
                                        let predictedDx = isFromRight ? -value.predictedEndTranslation.width : value.predictedEndTranslation.width
                                        let threshold = totalW * 0.32
                                        if dx > threshold || predictedDx > threshold * 1.3 {
                                            completePageTurn2D(forward: isFromRight, currentTravel: dx, totalW: totalW)
                                        } else {
                                            cancelPageTurn2D()
                                        }
                                    }
                            )
                    }
                    .frame(maxWidth: .infinity)

                    // Right Edge & Corner Turn Strip
                    Color.clear
                        .frame(width: 76)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 4)
                                .onChanged { value in
                                    guard !isAnimatingTurn else { return }
                                    if !isDragging {
                                        isDragging = true
                                        isFromRight = true
                                        UISelectionFeedbackGenerator().selectionChanged()
                                    }
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    guard !isAnimatingTurn else { return }
                                    let dx = -value.translation.width
                                    let predictedDx = -value.predictedEndTranslation.width
                                    let threshold = totalW * 0.32
                                    if dx > threshold || predictedDx > threshold * 1.3 {
                                        completePageTurn2D(forward: true, currentTravel: dx, totalW: totalW)
                                    } else {
                                        cancelPageTurn2D()
                                    }
                                }
                        )
                        .onTapGesture {
                            startTapPageTurn(forward: true)
                        }
                }
            }
        }
        .onAppear {
            singlePageIndex = currentSpreadIndex * 2
        }
        .onChange(of: currentSpreadIndex) { newIndex in
            if singlePageIndex / 2 != newIndex {
                singlePageIndex = newIndex * 2
            }
        }
    }

    private var centerSpineView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.18)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 20)

            Rectangle()
                .fill(Color.black.opacity(0.28))
                .frame(width: 1)

            VStack(spacing: 120) {
                StapleView(color: Color.gray)
                StapleView(color: Color.gray)
            }
        }
        .frame(width: 20)
    }

    private func startTapPageTurn(forward: Bool) {
        guard !isAnimatingTurn else { return }
        isFromRight = forward
        completePageTurn2D(forward: forward, currentTravel: 0.0, totalW: 1.0)
    }

    // Weighted, organic Kindle-style page turn spring physics with natural 2D lift arc
    private func completePageTurn2D(forward: Bool, currentTravel: CGFloat, totalW: CGFloat) {
        guard !isAnimatingTurn else { return }
        isAnimatingTurn = true
        isDragging = false
        isFromRight = forward

        let initialProgress = max(0.0, min(0.92, currentTravel / max(1.0, totalW)))
        turnProgress = initialProgress
        UISelectionFeedbackGenerator().selectionChanged()

        // Mass 1.15, stiffness 72, damping 14.5 replicates physical paper flex and smooth inertia
        withAnimation(.interpolatingSpring(mass: 1.15, stiffness: 72, damping: 14.5)) {
            turnProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.44) {
            if isWideDisplay {
                if forward {
                    if currentSpreadIndex < notebook.spreads.count - 1 {
                        currentSpreadIndex += 1
                    } else {
                        onAddSpread()
                    }
                    singlePageIndex = currentSpreadIndex * 2
                } else {
                    if currentSpreadIndex > 0 {
                        currentSpreadIndex -= 1
                    }
                    singlePageIndex = currentSpreadIndex * 2
                }
            } else {
                if forward {
                    if singlePageIndex + 1 < totalSinglePages {
                        singlePageIndex += 1
                        currentSpreadIndex = singlePageIndex / 2
                    } else {
                        onAddSpread()
                        singlePageIndex += 1
                        currentSpreadIndex = singlePageIndex / 2
                    }
                } else {
                    if singlePageIndex > 0 {
                        singlePageIndex -= 1
                        currentSpreadIndex = singlePageIndex / 2
                    } else {
                        onClose()
                    }
                }
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            turnProgress = 0.0
            dragOffset = .zero
            isAnimatingTurn = false
        }
    }

    private func cancelPageTurn2D() {
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 88, damping: 16)) {
            dragOffset = .zero
            turnProgress = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isDragging = false
        }
    }
}

// MARK: - Matte Finch 70# Cardstock 2D Dynamic Page Curl Canvas

struct KindlePageCurlCanvas2D: View {
    let state: KindleCurlGeometry2D.CurlState
    let isFromRight: Bool
    let totalSize: CGSize

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cb = state.cornerBottom
            let pb = state.creaseBottom
            let pts = state.creaseTopSide
            let ct = state.cornerTop
            let ctrlB = state.ctrlBottom
            let ctrlS = state.ctrlSide
            let lift = state.liftHeight
            let progress = state.progress

            guard lift > 0.5 || progress > 0.005 else { return }

            let bell = sin(progress * .pi)

            // Construct the complete, continuous flap path of the turned leaf
            var flapPath = Path()
            flapPath.move(to: pb)
            if let ct = ct {
                // Four-sided turned page (crease exits top edge)
                flapPath.addLine(to: pts)
                flapPath.addLine(to: ct)
                flapPath.addQuadCurve(to: cb, control: ctrlS)
                flapPath.addQuadCurve(to: pb, control: ctrlB)
            } else {
                // Three-sided turned corner (crease exits side edge)
                flapPath.addLine(to: pts)
                flapPath.addQuadCurve(to: cb, control: ctrlS)
                flapPath.addQuadCurve(to: pb, control: ctrlB)
            }
            flapPath.closeSubpath()

            // 1. Natural Floating Drop Shadow (Follows the lifted page, NOT fixed to screen bottom)
            let shadowOffset = CGSize(
                width: (isFromRight ? -6.0 : 6.0) - (isFromRight ? 1.0 : -1.0) * lift * 0.03,
                height: 5.0 + lift * 0.04
            )

            var floatingShadowPath = Path()
            floatingShadowPath.move(to: pb)
            if let ct = ct {
                floatingShadowPath.addLine(to: CGPoint(x: pts.x + shadowOffset.width, y: pts.y + shadowOffset.height))
                floatingShadowPath.addLine(to: CGPoint(x: ct.x + shadowOffset.width, y: ct.y + shadowOffset.height))
                floatingShadowPath.addQuadCurve(
                    to: CGPoint(x: cb.x + shadowOffset.width, y: cb.y + shadowOffset.height),
                    control: CGPoint(x: ctrlS.x + shadowOffset.width, y: ctrlS.y + shadowOffset.height)
                )
                floatingShadowPath.addQuadCurve(
                    to: pb,
                    control: CGPoint(x: ctrlB.x + shadowOffset.width * 0.6, y: ctrlB.y + shadowOffset.height * 0.6)
                )
            } else {
                floatingShadowPath.addLine(to: CGPoint(x: pts.x + shadowOffset.width, y: pts.y + shadowOffset.height))
                floatingShadowPath.addQuadCurve(
                    to: CGPoint(x: cb.x + shadowOffset.width, y: cb.y + shadowOffset.height),
                    control: CGPoint(x: ctrlS.x + shadowOffset.width, y: ctrlS.y + shadowOffset.height)
                )
                floatingShadowPath.addQuadCurve(
                    to: pb,
                    control: CGPoint(x: ctrlB.x + shadowOffset.width * 0.6, y: ctrlB.y + shadowOffset.height * 0.6)
                )
            }
            floatingShadowPath.closeSubpath()

            context.fill(
                floatingShadowPath,
                with: .color(Color(red: 0.16, green: 0.14, blue: 0.11).opacity(min(0.24, 0.08 + Double(lift) / 450.0)))
            )

            // 2. Soft contact shadow along the fold crease
            var tightShadowPath = Path()
            tightShadowPath.move(to: pb)
            tightShadowPath.addLine(to: pts)
            context.stroke(
                tightShadowPath,
                with: .color(Color(red: 0.18, green: 0.15, blue: 0.12).opacity(min(0.32, 0.12 + Double(bell) * 0.18))),
                lineWidth: 3.0
            )

            // 2. 100% SOLID OPAQUE MATTE FINCH 70# CARDSTOCK BASE
            // Warm cream uncoated paper with zero gloss or transparency
            context.fill(
                flapPath,
                with: .color(Color(red: 0.965, green: 0.952, blue: 0.925))
            )

            // 3. Subtle Printed 3/16" Graph Grid on the Reverse Face of the Sheet
            context.drawLayer { layerContext in
                layerContext.clip(to: flapPath)

                let gridStep: CGFloat = 14.0
                let gridColor = Color(red: 0.48, green: 0.58, blue: 0.68).opacity(0.18)
                var gridPath = Path()

                // Vertical grid lines
                var gx: CGFloat = 0
                while gx <= w + 40 {
                    gridPath.move(to: CGPoint(x: gx, y: -20))
                    gridPath.addLine(to: CGPoint(x: gx, y: h + 20))
                    gx += gridStep
                }

                // Horizontal grid lines
                var gy: CGFloat = 0
                while gy <= h + 40 {
                    gridPath.move(to: CGPoint(x: -20, y: gy))
                    gridPath.addLine(to: CGPoint(x: w + 20, y: gy))
                    gy += gridStep
                }

                layerContext.stroke(gridPath, with: .color(gridColor), lineWidth: 0.8)

                // 4. Subtle Matte Diffuse Shading Only (Zero Specular Shininess / No Gloss)
                // Natural soft ambient trough shadow at the crease, smoothly blending into matte paper
                let matteLightingColors = [
                    Color(red: 0.28, green: 0.24, blue: 0.19).opacity(min(0.20, 0.06 + Double(bell) * 0.14)), // Crease ambient trough
                    Color(red: 0.75, green: 0.72, blue: 0.66).opacity(0.12),
                    Color(red: 0.92, green: 0.90, blue: 0.85).opacity(0.04),
                    Color.clear
                ]

                let lightStart = CGPoint(x: (pb.x + pts.x) / 2, y: (pb.y + pts.y) / 2)
                let lightEnd = cb

                layerContext.fill(
                    flapPath,
                    with: .linearGradient(
                        Gradient(colors: matteLightingColors),
                        startPoint: lightStart,
                        endPoint: lightEnd
                    )
                )
            }

            // 5. Natural Matte Paper Fiber Edge (No Shiny Plastic Catch-Lights)
            var freeEdges = Path()
            freeEdges.move(to: pb)
            freeEdges.addQuadCurve(to: cb, control: ctrlB)
            if let ct = ct {
                freeEdges.addQuadCurve(to: ct, control: ctrlS)
                freeEdges.addLine(to: pts)
            } else {
                freeEdges.addQuadCurve(to: pts, control: ctrlS)
            }

            // Layer A: Soft warm edge shadow
            context.stroke(
                freeEdges,
                with: .color(Color(red: 0.25, green: 0.21, blue: 0.17).opacity(0.25)),
                lineWidth: 1.8
            )

            // Layer B: Natural matte paper fiber core (warm off-white cardstock tooth)
            context.stroke(
                freeEdges,
                with: .color(Color(red: 0.93, green: 0.91, blue: 0.86)),
                lineWidth: 1.2
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sketch Drawing Canvas

struct SketchDrawingCanvas: View {
    let strokes: [SketchStroke]
    let currentPoints: [CGPoint]

    var body: some View {
        Canvas { context, _ in
            for stroke in strokes {
                guard stroke.points.count > 1 else { continue }
                var path = Path()
                path.move(to: stroke.points[0].cgPoint)
                for pt in stroke.points.dropFirst() {
                    path.addLine(to: pt.cgPoint)
                }
                context.stroke(
                    path,
                    with: .color(Color(red: 0.16, green: 0.16, blue: 0.16).opacity(0.85)),
                    style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            if currentPoints.count > 1 {
                var currentPath = Path()
                currentPath.move(to: currentPoints[0])
                for pt in currentPoints.dropFirst() {
                    currentPath.addLine(to: pt)
                }
                context.stroke(
                    currentPath,
                    with: .color(Color(red: 0.16, green: 0.16, blue: 0.16).opacity(0.85)),
                    style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

// MARK: - Paper Pattern View

struct PaperPatternView: View {
    let style: PaperGridStyle

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 20.0

            switch style {
            case .graph:
                let linePath = Path { path in
                    var x: CGFloat = step
                    while x < size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y: CGFloat = step
                    while y < size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                }
                context.stroke(
                    linePath,
                    with: .color(Color(red: 0.65, green: 0.75, blue: 0.85).opacity(0.35)),
                    lineWidth: 0.5
                )

            case .dotGrid:
                var y: CGFloat = step
                while y < size.height {
                    var x: CGFloat = step
                    while x < size.width {
                        let dotRect = CGRect(x: x - 0.75, y: y - 0.75, width: 1.5, height: 1.5)
                        context.fill(Path(ellipseIn: dotRect), with: .color(Color.black.opacity(0.18)))
                        x += step
                    }
                    y += step
                }

            case .ruled:
                let linePath = Path { path in
                    var y: CGFloat = 26.0
                    while y < size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += 24.0
                    }
                }
                context.stroke(
                    linePath,
                    with: .color(Color(red: 0.4, green: 0.5, blue: 0.7).opacity(0.2)),
                    lineWidth: 0.7
                )

            case .blank:
                break
            }
        }
    }
}

// MARK: - Paper Grid Style Boxed Picker

struct PaperGridStylePicker: View {
    @Binding var selection: PaperGridStyle

    var body: some View {
        HStack(spacing: 6) {
            ForEach(PaperGridStyle.allCases) { style in
                let isSelected = (selection == style)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selection = style
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: style.iconName)
                            .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                        Text(style.shortName)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(isSelected ? .orange : Color(red: 0.35, green: 0.30, blue: 0.25))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isSelected ? Color.orange.opacity(0.85) : Color(red: 0.35, green: 0.30, blue: 0.25).opacity(0.3),
                                lineWidth: isSelected ? 1.5 : 1.0
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notebook 3-Pack Shelf Sheet

struct NotebookShelfSheet: View {
    var store: NotebookStore
    let onSelectNotebook: (Int) -> Void
    let onAddNew: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Shelf Vintage Header Bar
                HStack {
                    Text("NOTEBOOK SHELF")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }) {
                        Text("DONE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YOUR POCKET ARCHIVE")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("SELECT OR START A NEW EXPEDITION")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // 3-Pack Stack
                        LazyVStack(spacing: 16) {
                            ForEach(store.notebooks.indices, id: \.self) { idx in
                                let book = store.notebooks[idx]
                                Button(action: {
                                    onSelectNotebook(idx)
                                }) {
                                    HStack(spacing: 16) {
                                        // Miniature cover
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(book.coverColor.background)
                                                .frame(width: 50, height: 75)

                                            VStack(spacing: 16) {
                                                Circle().fill(Color.gray).frame(width: 2, height: 8)
                                                Circle().fill(Color.gray).frame(width: 2, height: 8)
                                            }
                                            .offset(x: -20)
                                        }

                                        // Details
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(book.title.uppercased())
                                                    .font(.system(size: 14, weight: .black, design: .default))
                                                    .foregroundColor(.white)
                                                if idx == store.selectedNotebookIndex {
                                                    Text("ACTIVE")
                                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                        .foregroundColor(.orange)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.orange.opacity(0.2))
                                                        .cornerRadius(4)
                                                }
                                            }

                                            Text("PROJECT: \(book.projectName)")
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.7))

                                            Text("\(book.spreads.count * 2) PAGES · \(book.paperStyle.rawValue.uppercased())")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(idx == store.selectedNotebookIndex ? Color.orange : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                            }
                        }

                        // Add new notebook button (Rectangle box with curved corners like cover letter)
                        Button(action: onAddNew) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("START A NEW NOTEBOOK")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.orange.opacity(0.65), lineWidth: 1.5)
                            )
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - New Notebook Sheet

struct NewNotebookSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = "FOLIO"
    @State private var subtitle = "DUO MEMO BOOK"
    @State private var owner = "J. HUDSON"
    @State private var project = "LOG 03"
    @State private var coverColor: CoverColor = .expeditionOrange
    @State private var paperStyle: PaperGridStyle = .graph

    let onCreated: (String, String, String, String, CoverColor, PaperGridStyle) -> Void

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("NEW MEMO BOOK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onCreated(title, subtitle, owner, project, coverColor, paperStyle)
                        dismiss()
                    }) {
                        Text("CREATE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 6)

                Form {
                    Section(header: Text("Cover Colorway")) {
                        Picker("Color", selection: $coverColor) {
                            ForEach(CoverColor.allCases) { color in
                                HStack {
                                    Circle()
                                        .fill(color.background)
                                        .frame(width: 14, height: 14)
                                    Text(color.rawValue)
                                }
                                .tag(color)
                            }
                        }
                        .pickerStyle(.inline)
                    }

                    Section(header: Text("Interior Paper Grid")) {
                        PaperGridStylePicker(selection: $paperStyle)
                    }

                    Section(header: Text("Cover Details")) {
                        TextField("Title", text: $title)
                        TextField("Subtitle", text: $subtitle)
                        TextField("Owner", text: $owner)
                        TextField("Project / Subject", text: $project)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Cover Customizer Sheet

struct CoverCustomizerSheet: View {
    @Binding var notebook: FieldNotebook
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar (Seamlessly merged on unified systemGroupedBackground)
                HStack {
                    // Balance the right button so title is centered
                    Color.clear
                        .frame(width: 50, height: 26)

                    Spacer()

                    Text("CUSTOMIZE COVER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.18))

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSave()
                        dismiss()
                    }) {
                        Text("DONE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 6)

                Form {
                    Section(header: Text("Cover Colorway")) {
                        Picker("Color", selection: $notebook.coverColor) {
                            ForEach(CoverColor.allCases) { color in
                                HStack {
                                    Circle()
                                        .fill(color.background)
                                        .frame(width: 14, height: 14)
                                    Text(color.rawValue)
                                }
                                .tag(color)
                            }
                        }
                        .pickerStyle(.inline)
                    }

                    Section(header: Text("Interior Paper Grid")) {
                        PaperGridStylePicker(selection: $notebook.paperStyle)
                    }

                    Section(header: Text("Front Cover Lettering")) {
                        TextField("Notebook Title", text: $notebook.title)
                        TextField("Subtitle", text: $notebook.subtitle)
                        TextField("Project / Subject", text: $notebook.projectName)
                        TextField("Owner / Name", text: $notebook.ownerName)
                        TextField("Practical Applications", text: $notebook.practicalApplications, axis: .vertical)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    ContentView()
}
