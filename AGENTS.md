# AGENTS.md — SwiftUI_Mysticbook

## Project
macOS outliner app (SwiftUI + AppKit). Xcode project, no SPM/CocoaPods.

## Build & Run
```
xcodebuild -project SwiftUI_Mysticbook/SwiftUI_Mysticbook.xcodeproj -scheme SwiftUI_Mysticbook build
open SwiftUI_Mysticbook/SwiftUI_Mysticbook.xcodeproj
```

## Tests
- Unit tests use **Swift Testing** (`import Testing`, `@Test` macros)
- UI tests use **XCTest** (`import XCTest`, `XCTestCase`)
- Run all: `xcodebuild test -project SwiftUI_Mysticbook/SwiftUI_Mysticbook.xcodeproj -scheme SwiftUI_Mysticbook -sdk macosx`
- Run unit tests only: `xcodebuild test -project SwiftUI_Mysticbook/SwiftUI_Mysticbook.xcodeproj -scheme SwiftUI_Mysticbook -only-testing:SwiftUI_MysticbookTests -sdk macosx`
- `OutlineNoderControllerTest.swift` references `OutlinerNode(content:...)` and `OutlinerNodeController` — these APIs no longer exist (current codebase uses `text:` initializer). Test will fail until updated.

## File System Groups
Project uses `PBXFileSystemSynchronizedRootGroup`. Files added in Finder are auto-included — no `project.pbxproj` edits needed.

## Architecture
| Directory | Role |
|-----------|------|
| `SwiftUI_MysticbookApp.swift` | @main entrypoint, hosts ContentView + menu bar |
| `AppKit/` | AppKit bridge: `Outliner.swift` (NSViewRepresentable wrapping NSOutlineView), `OutlinerNode.swift`, `OutlinerDocument.swift` (indent/unindent/split/merge) |
| `SwiftUI_Backend/` | Service layer: `FileSystemServiceProtocol` + `FileSystemService` |
| `CommandPaletteView.swift` | Overlay, toggled via Cmd+/ |

## In-app keyboard shortcuts
| Key | Action |
|-----|--------|
| Enter | Split node at cursor |
| Shift+Enter | Insert newline in node text |
| Delete (at pos 0) | Merge node with parent/previous sibling |
| Tab | Indent node |
| Shift+Tab | Unindent node |
| Cmd+/ | Open command palette |
