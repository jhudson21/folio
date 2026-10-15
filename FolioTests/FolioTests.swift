//
//  FolioTests.swift
//  FolioTests
//
//  Created by Jordan Hudson on 15/10/2026.
//

import Testing
import CoreGraphics
import Foundation
@testable import Folio

struct FolioModelTests {

    @Test func testCoverColorPaletteAndTextColors() {
        for color in CoverColor.allCases {
            let bg = color.background
            let text = color.textColor
            let staple = color.stapleColor
            #expect(color.rawValue.count > 0)
        }
    }

    @Test func testPaperGridStyles() {
        #expect(PaperGridStyle.graph.shortName == "GRAPH")
        #expect(PaperGridStyle.dotGrid.shortName == "DOT GRID")
        #expect(PaperGridStyle.ruled.shortName == "RULED")
        #expect(PaperGridStyle.blank.shortName == "BLANK")

        #expect(PaperGridStyle.graph.iconName == "grid")
        #expect(PaperGridStyle.dotGrid.iconName == "circle.grid.2x2")
        #expect(PaperGridStyle.ruled.iconName == "line.horizontal.3")
        #expect(PaperGridStyle.blank.iconName == "doc.plaintext")
    }

    @Test func testCodablePointConversion() {
        let cgPoint = CGPoint(x: 123.45, y: 678.90)
        let codablePoint = CodablePoint(cgPoint: cgPoint)

        #expect(codablePoint.x == 123.45)
        #expect(codablePoint.y == 678.90)
        #expect(codablePoint.cgPoint.x == 123.45)
        #expect(codablePoint.cgPoint.y == 678.90)
    }

    @Test func testChecklistItemToggle() {
        var item = FieldChecklistItem(text: "Inspect binding", isDone: false)
        #expect(!item.isDone)
        item.isDone.toggle()
        #expect(item.isDone)
    }

    @Test func testNotebookSpreadSerialization() throws {
        let item1 = FieldChecklistItem(text: "Check weather", isDone: true)
        let item2 = FieldChecklistItem(text: "Record waypoint", isDone: false)
        let stroke = SketchStroke(
            points: [CodablePoint(cgPoint: CGPoint(x: 10, y: 20)), CodablePoint(cgPoint: CGPoint(x: 30, y: 40))],
            colorHex: "#2A2A2A",
            lineWidth: 2.0
        )
        let spread = NotebookSpread(
            spreadIndex: 1,
            dateStamp: "OCT 15, 2026",
            weatherStamp: "62°F · OVERCAST",
            locationStamp: "CUPERTINO HQ",
            checklist: [item1, item2],
            memoText: "Field testing session.",
            sketchStrokes: [stroke]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(spread)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NotebookSpread.self, from: data)

        #expect(decoded.id == spread.id)
        #expect(decoded.spreadIndex == spread.spreadIndex)
        #expect(decoded.dateStamp == spread.dateStamp)
        #expect(decoded.weatherStamp == spread.weatherStamp)
        #expect(decoded.locationStamp == spread.locationStamp)
        #expect(decoded.checklist.count == 2)
        #expect(decoded.checklist[0].isDone == true)
        #expect(decoded.checklist[1].isDone == false)
        #expect(decoded.memoText == spread.memoText)
        #expect(decoded.sketchStrokes.count == 1)
        #expect(decoded.sketchStrokes[0].points.count == 2)
    }

    @Test func testNotebookCreationAndAddingSpreads() {
        let initialSpread = NotebookSpread(
            spreadIndex: 1,
            dateStamp: "OCT 15, 2026",
            weatherStamp: "62°F · FAIR",
            locationStamp: "BASE CAMP",
            checklist: [],
            memoText: "Day 1 Notes",
            sketchStrokes: []
        )
        var notebook = FieldNotebook(
            title: "TEST BOOK",
            subtitle: "TRAIL MEMO",
            ownerName: "EXPLORER",
            projectName: "EXPEDITION",
            coverColor: .shenandoahPine,
            paperStyle: .dotGrid,
            dateStarted: "OCTOBER 2026",
            practicalApplications: "Field notes",
            spreads: [initialSpread]
        )

        #expect(notebook.spreads.count == 1)

        let nextSpread = NotebookSpread(
            spreadIndex: 2,
            dateStamp: "OCT 16, 2026",
            weatherStamp: "58°F · CLEAR",
            locationStamp: "CAMP 2",
            checklist: [FieldChecklistItem(text: "Check pack weight", isDone: true)],
            memoText: "Day 2 Notes",
            sketchStrokes: []
        )
        notebook.spreads.append(nextSpread)

        #expect(notebook.spreads.count == 2)
        #expect(notebook.spreads[1].checklist.count == 1)
    }

    @Test func testIsDuoAspectRatioClassification() {
        // iPhone Duo Folded: 466 x 678 (ratio ~1.455 < 1.6)
        let duoFolded = CGSize(width: 466, height: 678)
        #expect(isDuoAspectRatio(geometrySize: duoFolded) == true)

        // iPhone Duo Unfolded: 932 x 678 (ratio ~1.375 < 1.6)
        let duoUnfolded = CGSize(width: 932, height: 678)
        #expect(isDuoAspectRatio(geometrySize: duoUnfolded) == true)

        // Standard iPhone 18 Pro: 402 x 874 (ratio ~2.174 > 1.6)
        let iphone18Pro = CGSize(width: 402, height: 874)
        #expect(isDuoAspectRatio(geometrySize: iphone18Pro) == false)

        // Standard iPhone 16 / 17: 393 x 852 (ratio ~2.168 > 1.6)
        let iphone16 = CGSize(width: 393, height: 852)
        #expect(isDuoAspectRatio(geometrySize: iphone16) == false)

        // Classic iPhone SE: 375 x 667 (ratio ~1.778 > 1.6)
        let iphoneSE = CGSize(width: 375, height: 667)
        #expect(isDuoAspectRatio(geometrySize: iphoneSE) == false)
    }
}
