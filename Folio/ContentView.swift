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

        let initialBook = FieldNotebook(
            title: "FOLIO",
            subtitle: "DUO MEMO BOOK",
            ownerName: "J. HUDSON",
            projectName: "IPHONE DUO PROTOTYPE",
            coverColor: .kraft,
            paperStyle: .graph,
            dateStarted: "OCTOBER 15, 2026",
            practicalApplications: "01. Fleeting thoughts  02. Escape routes\n03. Dual-screen sketches  04. Coffee notes",
            spreads: [spread1]
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

// MARK: - Main Content View

struct ContentView: View {
    @State private var store = NotebookStore()
    @State private var isOpen = false
    @State private var currentSpreadIndex = 0
    @State private var showShelf = false
    @State private var showCustomizer = false
    @State private var showNewBookSheet = false
    @State private var showPracticalGuide = false

    var body: some View {
        GeometryReader { geometry in
            let isWideDisplay = geometry.size.width > 700

            ZStack {
                // Background surface
                Color(red: 0.12, green: 0.12, blue: 0.13)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Navigation & Posture Bar
                    topBar(isWideDisplay: isWideDisplay)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    if let currentNotebook = store.currentNotebook {
                        ZStack {
                            if isOpen || isWideDisplay {
                                // Interior Two-Page Spread
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
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                    removal: .opacity.combined(with: .scale(scale: 0.96))
                                ))
                            } else {
                                // Closed Front Cover View
                                NotebookCoverView(
                                    notebook: currentNotebook,
                                    onOpen: {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                            isOpen = true
                                        }
                                    },
                                    onCustomize: {
                                        showCustomizer = true
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                    removal: .opacity.combined(with: .scale(scale: 0.96))
                                ))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, isWideDisplay ? 24 : 16)
                        .padding(.bottom, 16)
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
            PracticalGuideSheet()
        }
    }

    // Top control bar
    private func topBar(isWideDisplay: Bool) -> some View {
        HStack {
            // Shelf / 3-Pack selector button
            Button(action: { showShelf = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 13))
                    Text("3-PACK SHELF (\(store.notebooks.count))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .cornerRadius(12)
            }

            Spacer()

            // Mode indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text(isWideDisplay ? "UNFOLDED SPREAD" : (isOpen ? "OPEN SPREAD" : "COVER SCREEN"))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)

            Spacer()

            // Open/Close toggle (for compact testing)
            if !isWideDisplay {
                Button(action: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        isOpen.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isOpen ? "book.closed.fill" : "book.fill")
                        Text(isOpen ? "Fold" : "Open")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
            }

            // Customize button
            Button(action: { showCustomizer = true }) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.white)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Notebook Cover View

struct NotebookCoverView: View {
    let notebook: FieldNotebook
    let onOpen: () -> Void
    let onCustomize: () -> Void

    var body: some View {
        ZStack {
            // Heavy Cardstock Base with tactile texture
            RoundedRectangle(cornerRadius: 16)
                .fill(notebook.coverColor.background)
                .shadow(color: .black.opacity(0.4), radius: 15, x: 5, y: 10)

            // Staple impressions along the left edge
            HStack {
                VStack(spacing: 90) {
                    StapleView(color: notebook.coverColor.stapleColor)
                    StapleView(color: notebook.coverColor.stapleColor)
                    StapleView(color: notebook.coverColor.stapleColor)
                }
                .padding(.leading, 12)

                Spacer()
            }

            // Cover Layout
            VStack(spacing: 16) {
                // Header badge
                VStack(spacing: 4) {
                    Text(notebook.title.uppercased())
                        .font(.system(size: 32, weight: .black, design: .default))
                        .tracking(3)
                        .foregroundColor(notebook.coverColor.textColor)

                    Text(notebook.subtitle.uppercased())
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(notebook.coverColor.textColor.opacity(0.85))
                }
                .padding(.top, 24)

                // Stamped Specifications Box
                VStack(alignment: .leading, spacing: 10) {
                    specRow(label: "PROJECT", value: notebook.projectName)
                    Divider().background(notebook.coverColor.textColor.opacity(0.3))
                    specRow(label: "RECORDED BY", value: notebook.ownerName)
                    Divider().background(notebook.coverColor.textColor.opacity(0.3))
                    specRow(label: "STARTED", value: notebook.dateStarted)
                    Divider().background(notebook.coverColor.textColor.opacity(0.3))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRACTICAL APPLICATIONS:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.8))
                        Text(notebook.practicalApplications)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(notebook.coverColor.textColor.opacity(0.75))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(notebook.coverColor.textColor.opacity(0.4), lineWidth: 1.5)
                )
                .padding(.horizontal, 28)

                Spacer()

                // Bottom Manufacturer Stamp
                VStack(spacing: 6) {
                    Text("48 PAGES · 3-1/2″ × 5-1/2″ · \(notebook.paperStyle.rawValue.uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(notebook.coverColor.textColor.opacity(0.8))

                    Text("TAILORED FOR IPHONE DUO · CUPERTINO & CHICAGO")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(notebook.coverColor.textColor.opacity(0.65))
                }
                .padding(.bottom, 16)

                // Interactive "Open" action strip
                Button(action: onOpen) {
                    HStack {
                        Text("OPEN NOTEBOOK")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(1)
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(notebook.coverColor.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(notebook.coverColor.textColor)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .aspectRatio(3.5 / 5.5, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
        )
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

// MARK: - Interactive Corner Page Pull Component

struct InteractiveCornerPullView: View {
    let isRightCorner: Bool
    let isNewPage: Bool
    let onCompleteTurn: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var animatedPull: CGFloat = 22.0

    private let restingPull: CGFloat = 22.0
    private let triggerThreshold: CGFloat = 75.0

    var currentPull: CGFloat {
        if isDragging {
            let delta = isRightCorner ? -dragOffset.width : dragOffset.width
            return max(restingPull, min(220, restingPull + delta))
        }
        return animatedPull
    }

    var body: some View {
        ZStack(alignment: isRightCorner ? .bottomTrailing : .bottomLeading) {
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let pull = currentPull

                if isRightCorner {
                    let corner = CGPoint(x: w, y: h)
                    let apex = CGPoint(x: max(0, w - pull), y: max(0, h - pull * 0.82))
                    let creaseBottom = CGPoint(x: max(0, w - pull * 1.35), y: h)
                    let creaseRight = CGPoint(x: w, y: max(0, h - pull * 1.35))

                    // 1. Shadow underneath the curling corner
                    var shadowPath = Path()
                    shadowPath.move(to: creaseBottom)
                    shadowPath.addQuadCurve(
                        to: creaseRight,
                        control: CGPoint(x: apex.x - 8, y: apex.y + 8)
                    )
                    shadowPath.addLine(to: corner)
                    shadowPath.closeSubpath()
                    context.fill(
                        shadowPath,
                        with: .color(Color.black.opacity(min(0.38, 0.15 + (pull / 260))))
                    )

                    // 2. Underneath revealed page peek
                    var peekPath = Path()
                    peekPath.move(to: creaseBottom)
                    peekPath.addLine(to: corner)
                    peekPath.addLine(to: creaseRight)
                    peekPath.closeSubpath()
                    context.fill(peekPath, with: .color(Color(red: 0.94, green: 0.92, blue: 0.88)))

                    // 3. Curled paper flap (back of current page lifting up)
                    var flapPath = Path()
                    flapPath.move(to: creaseBottom)
                    flapPath.addQuadCurve(
                        to: apex,
                        control: CGPoint(x: (creaseBottom.x + apex.x) / 2, y: h - 3)
                    )
                    flapPath.addQuadCurve(
                        to: creaseRight,
                        control: CGPoint(x: w - 3, y: (creaseRight.y + apex.y) / 2)
                    )
                    flapPath.closeSubpath()

                    context.fill(
                        flapPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 0.85, green: 0.82, blue: 0.75),
                                Color(red: 0.93, green: 0.90, blue: 0.85),
                                Color(red: 0.98, green: 0.96, blue: 0.92)
                            ]),
                            startPoint: creaseBottom,
                            endPoint: apex
                        )
                    )

                    context.stroke(flapPath, with: .color(Color.black.opacity(0.18)), lineWidth: 0.8)
                } else {
                    let corner = CGPoint(x: 0, y: h)
                    let apex = CGPoint(x: min(w, pull), y: max(0, h - pull * 0.82))
                    let creaseBottom = CGPoint(x: min(w, pull * 1.35), y: h)
                    let creaseLeft = CGPoint(x: 0, y: max(0, h - pull * 1.35))

                    var shadowPath = Path()
                    shadowPath.move(to: creaseBottom)
                    shadowPath.addQuadCurve(
                        to: creaseLeft,
                        control: CGPoint(x: apex.x + 8, y: apex.y + 8)
                    )
                    shadowPath.addLine(to: corner)
                    shadowPath.closeSubpath()
                    context.fill(
                        shadowPath,
                        with: .color(Color.black.opacity(min(0.38, 0.15 + (pull / 260))))
                    )

                    var peekPath = Path()
                    peekPath.move(to: creaseBottom)
                    peekPath.addLine(to: corner)
                    peekPath.addLine(to: creaseLeft)
                    peekPath.closeSubpath()
                    context.fill(peekPath, with: .color(Color(red: 0.94, green: 0.92, blue: 0.88)))

                    var flapPath = Path()
                    flapPath.move(to: creaseBottom)
                    flapPath.addQuadCurve(
                        to: apex,
                        control: CGPoint(x: (creaseBottom.x + apex.x) / 2, y: h - 3)
                    )
                    flapPath.addQuadCurve(
                        to: creaseLeft,
                        control: CGPoint(x: 3, y: (creaseLeft.y + apex.y) / 2)
                    )
                    flapPath.closeSubpath()

                    context.fill(
                        flapPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 0.85, green: 0.82, blue: 0.75),
                                Color(red: 0.93, green: 0.90, blue: 0.85),
                                Color(red: 0.98, green: 0.96, blue: 0.92)
                            ]),
                            startPoint: creaseBottom,
                            endPoint: apex
                        )
                    )

                    context.stroke(flapPath, with: .color(Color.black.opacity(0.18)), lineWidth: 0.8)
                }
            }
            .frame(width: 80, height: 60)

            // Touch cue label
            Text(isRightCorner ? (isNewPage ? "+ NEW" : "PULL ⤹") : "⤸ PREV")
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 0.40, green: 0.35, blue: 0.30))
                .padding(isRightCorner ? .trailing : .leading, 6)
                .padding(.bottom, 4)
                .opacity(isDragging ? 0 : 0.8)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let delta = isRightCorner ? -value.translation.width : value.translation.width
                    if delta > triggerThreshold {
                        withAnimation(.easeIn(duration: 0.22)) {
                            animatedPull = 240
                        }
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            onCompleteTurn()
                            animatedPull = restingPull
                            isDragging = false
                            dragOffset = .zero
                        }
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            isDragging = false
                            dragOffset = .zero
                            animatedPull = restingPull
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.24)) {
                animatedPull = 240
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                onCompleteTurn()
                animatedPull = restingPull
            }
        }
    }
}

// MARK: - Notebook Interior (Two-Page Spread)

enum RightPageMode {
    case memo
    case sketch
}

struct NotebookInteriorView: View {
    let notebook: FieldNotebook
    @Binding var currentSpreadIndex: Int
    let isWideDisplay: Bool
    let onUpdateSpread: (NotebookSpread) -> Void
    let onAddSpread: () -> Void
    let onClose: () -> Void
    let onOpenGuide: () -> Void

    @State private var newChecklistText = ""
    @State private var rightPageMode: RightPageMode = .memo
    @State private var currentDrawingPoints: [CGPoint] = []

    // Interactive Page Turn Animation State
    @State private var isTurningPage: Bool = false
    @State private var turnAngle: Double = 0.0
    @State private var turnDirection: Int = 1 // 1: next, -1: prev

    var activeSpread: NotebookSpread {
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

    var body: some View {
        VStack(spacing: 8) {
            // Main Spread Canvas with 3D Page Turn Effect
            ZStack {
                // Background Paper Spread Base
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
                    .shadow(color: .black.opacity(isTurningPage ? 0.45 : 0.35), radius: isTurningPage ? 24 : 18, x: 0, y: isTurningPage ? 12 : 8)

                // Grid / Dot / Ruled background overlay
                PaperPatternView(style: notebook.paperStyle)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Spread content (Left Page, Spine, Right Page)
                HStack(spacing: 0) {
                    // LEFT PAGE: Field Observations & Checklist
                    leftPageView
                        .padding(isWideDisplay ? 20 : 14)
                        .frame(maxWidth: .infinity)

                    // CENTER GUTTER / HINGE SPINE
                    centerSpineView

                    // RIGHT PAGE: Memo or Sketch Canvas
                    rightPageView
                        .padding(isWideDisplay ? 20 : 14)
                        .frame(maxWidth: .infinity)
                }

                // Mid-turn shadow overlay on gutter
                if isTurningPage {
                    Color.black.opacity(0.12)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            // 3D Rotation along the spine hinge
            .rotation3DEffect(
                .degrees(turnAngle),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                anchor: turnDirection == 1 ? .trailing : .leading,
                perspective: 0.45
            )
            .contentShape(Rectangle())
            // Touch Swipe Gestures to turn pages
            .gesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { value in
                        // Only swipe pages if not actively drawing in sketch mode
                        if rightPageMode == .memo || value.startLocation.x < 220 {
                            if value.translation.width < -50 {
                                turnPage(forward: true)
                            } else if value.translation.width > 50 {
                                turnPage(forward: false)
                            }
                        }
                    }
            )

            // Bottom Spread Pagination Bar
            paginationBar
        }
    }

    // Touch Page Turn Method
    private func turnPage(forward: Bool) {
        guard !isTurningPage else { return }

        if forward {
            if currentSpreadIndex < notebook.spreads.count - 1 {
                isTurningPage = true
                turnDirection = 1
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                withAnimation(.easeInOut(duration: 0.25)) {
                    turnAngle = -85
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    currentSpreadIndex += 1
                    turnAngle = 85
                    withAnimation(.easeOut(duration: 0.22)) {
                        turnAngle = 0
                        isTurningPage = false
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            } else {
                onAddSpread()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        } else {
            if currentSpreadIndex > 0 {
                isTurningPage = true
                turnDirection = -1
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                withAnimation(.easeInOut(duration: 0.25)) {
                    turnAngle = 85
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    currentSpreadIndex -= 1
                    turnAngle = -85
                    withAnimation(.easeOut(duration: 0.22)) {
                        turnAngle = 0
                        isTurningPage = false
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            }
        }
    }

    // Left Page
    private var leftPageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Left page header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FIELD OBSERVATIONS")
                        .font(.system(size: 13, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.18))
                    Text("\(activeSpread.dateStamp) · \(activeSpread.weatherStamp)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                }
                Spacer()
                Button(action: onOpenGuide) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.35, green: 0.30, blue: 0.25))
                }
            }

            // Checklist section
            Text("EXPEDITION CHECKLIST:")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(activeSpread.checklist) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Button(action: {
                                toggleChecklistItem(item.id)
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
                    guard !newChecklistText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    var spread = activeSpread
                    spread.checklist.append(FieldChecklistItem(text: newChecklistText, isDone: false))
                    onUpdateSpread(spread)
                    newChecklistText = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.orange)
                }
            }

            Spacer()

            // Left page footer with Interactive Corner Pull button
            HStack(alignment: .bottom) {
                if currentSpreadIndex > 0 {
                    InteractiveCornerPullView(
                        isRightCorner: false,
                        isNewPage: false,
                        onCompleteTurn: {
                            turnPage(forward: false)
                        }
                    )
                }

                Text("PAGE \(String(format: "%02d", (currentSpreadIndex * 2) + 1))")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.gray.opacity(0.8))
                    .padding(.bottom, 4)

                Spacer()
            }
        }
    }

    // Center Spine
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
            .frame(width: 22)

            Rectangle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 1)

            VStack(spacing: 120) {
                StapleView(color: Color.gray)
                StapleView(color: Color.gray)
            }
        }
    }

    // Right Page
    private var rightPageView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Right page header & Mode toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rightPageMode == .memo ? "MEMO & LOG BOOK" : "FIELD SKETCH")
                        .font(.system(size: 13, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.18))
                    Text("LOC: \(activeSpread.locationStamp)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.45, green: 0.40, blue: 0.35))
                }

                Spacer()

                // Mode switch: Memo vs Sketch
                Picker("Mode", selection: $rightPageMode) {
                    Image(systemName: "doc.text").tag(RightPageMode.memo)
                    Image(systemName: "pencil.and.scribble").tag(RightPageMode.sketch)
                }
                .pickerStyle(.segmented)
                .frame(width: 90)

                if !isWideDisplay {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.gray.opacity(0.7))
                    }
                }
            }

            // Right page body: Editor or Canvas
            if rightPageMode == .memo {
                TextEditor(text: Binding(
                    get: { activeSpread.memoText },
                    set: { newText in
                        var spread = activeSpread
                        spread.memoText = newText
                        onUpdateSpread(spread)
                    }
                ))
                .font(.system(size: 12, design: .serif))
                .foregroundColor(Color(red: 0.2, green: 0.18, blue: 0.15))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .lineSpacing(6)
            } else {
                // Interactive Field Sketch Canvas
                ZStack {
                    SketchDrawingCanvas(
                        strokes: activeSpread.sketchStrokes,
                        currentPoints: currentDrawingPoints
                    )

                    // Clear button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                var spread = activeSpread
                                spread.sketchStrokes.removeAll()
                                onUpdateSpread(spread)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text("Erase")
                                }
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(4)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(4)
                            }
                        }
                        Spacer()
                    }
                    .padding(4)
                }
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
                                var spread = activeSpread
                                let newStroke = SketchStroke(
                                    points: currentDrawingPoints.map { CodablePoint(cgPoint: $0) },
                                    colorHex: "#2A2A2A",
                                    lineWidth: 2.0
                                )
                                spread.sketchStrokes.append(newStroke)
                                onUpdateSpread(spread)
                                currentDrawingPoints = []
                            }
                        }
                )
            }

            Spacer()

            // Right page footer with Interactive Corner Pull button
            HStack(alignment: .bottom) {
                Spacer()
                Text("PAGE \(String(format: "%02d", (currentSpreadIndex * 2) + 2)) · FOLIO")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.gray.opacity(0.8))
                    .padding(.bottom, 4)

                InteractiveCornerPullView(
                    isRightCorner: true,
                    isNewPage: currentSpreadIndex == notebook.spreads.count - 1
                ) {
                    turnPage(forward: true)
                }
            }
        }
    }

    // Pagination controls
    private var paginationBar: some View {
        HStack {
            Button(action: {
                turnPage(forward: false)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentSpreadIndex > 0 ? .white : .white.opacity(0.3))
            }
            .disabled(currentSpreadIndex == 0)

            Spacer()

            Text("SPREAD \(currentSpreadIndex + 1) OF \(notebook.spreads.count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Button(action: {
                turnPage(forward: true)
            }) {
                HStack(spacing: 4) {
                    if currentSpreadIndex == notebook.spreads.count - 1 {
                        Image(systemName: "plus")
                        Text("New Page")
                    } else {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private func toggleChecklistItem(_ id: UUID) {
        var spread = activeSpread
        if let idx = spread.checklist.firstIndex(where: { $0.id == id }) {
            spread.checklist[idx].isDone.toggle()
            onUpdateSpread(spread)
        }
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

// MARK: - Notebook 3-Pack Shelf Sheet

struct NotebookShelfSheet: View {
    var store: NotebookStore
    let onSelectNotebook: (Int) -> Void
    let onAddNew: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.12, blue: 0.13)
                    .ignoresSafeArea()

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

                        // Add new notebook button
                        Button(action: onAddNew) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("START A NEW NOTEBOOK")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Notebook Shelf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
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
        NavigationStack {
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
                    Picker("Paper Style", selection: $paperStyle) {
                        ForEach(PaperGridStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Cover Details")) {
                    TextField("Title", text: $title)
                    TextField("Subtitle", text: $subtitle)
                    TextField("Owner", text: $owner)
                    TextField("Project / Subject", text: $project)
                }
            }
            .navigationTitle("New Memo Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreated(title, subtitle, owner, project, coverColor, paperStyle)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
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
        NavigationStack {
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
                    Picker("Paper Style", selection: $notebook.paperStyle) {
                        ForEach(PaperGridStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Front Cover Lettering")) {
                    TextField("Notebook Title", text: $notebook.title)
                    TextField("Subtitle", text: $notebook.subtitle)
                    TextField("Project / Subject", text: $notebook.projectName)
                    TextField("Owner / Name", text: $notebook.ownerName)
                    TextField("Practical Applications", text: $notebook.practicalApplications, axis: .vertical)
                }
            }
            .navigationTitle("Customize Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Quirky Practical Guide Sheet

struct PracticalGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRACTICAL GUIDE & FIELD RULES")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                        Text("FOLIO × IPHONE DUO EDITION")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("01. HANDY CONVERSIONS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text("• 1 Inch = 25.4 mm = 72 PostScript points\n• 1 Meter = 39.37 Inches = 3.28 Feet\n• 1 Knot = 1.150779 MPH = 1.852 km/h\n• Boiling Point = 212°F = 100°C")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("02. EMERGENCY MORSE CODE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text("• S.O.S. = · · ·  — — —  · · ·\n• YES = — · — —  ·  · · ·\n• NO = — ·  — — —")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("03. GOLDEN RULES FOR NOTE TAKING")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text("1. Write down ideas immediately before they evaporate.\n2. Don't worry about messy handwriting.\n3. A notebook in your pocket is worth ten in a drawer.\n4. Fold the Duo when walking, unfold when inspiration strikes.")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Practical Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
