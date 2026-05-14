import SwiftUI

struct FlatFile: Identifiable {
	let url: URL
	let name: String
	let rootNodeText: String
	let parentDir: String?
	var id: URL { url }
	var displayTitle: String { rootNodeText.isEmpty ? name : rootNodeText }
}

private func flattenFileTree(_ items: [FileItem]) -> [FlatFile] {
	var result: [FlatFile] = []
	for item in items {
		if item.isDirectory, let children = item.children {
			result.append(contentsOf: flattenFileTree(children))
		} else if !item.isDirectory {
			let parent = item.url.deletingLastPathComponent()
			let parentName = parent.lastPathComponent
			let text = readRootNodeText(from: item.url)
			result.append(FlatFile(url: item.url, name: item.name, rootNodeText: text, parentDir: parentName == "/" ? nil : parentName))
		}
	}
	return result
}

private func readRootNodeText(from url: URL) -> String {
	guard let content = try? String(contentsOf: url, encoding: .utf8) else { return "" }
	var firstMeaningful: String?
	for line in content.split(separator: "\n") {
		let trimmed = line.trimmingCharacters(in: .whitespaces)
		if trimmed.hasPrefix("#+TITLE: ") {
			return String(trimmed.dropFirst(9))
		}
		if firstMeaningful == nil, !trimmed.hasPrefix("#+"), !trimmed.hasPrefix(":") {
			firstMeaningful = trimmed
		}
	}
	if let text = firstMeaningful {
		return text.hasPrefix("* ") ? String(text.dropFirst(2)) : text
	}
	return ""
}

struct CommandPaletteView: View {
	@Binding var isPresented: Bool
	var files: [FileItem]
	var workspaceDirectoryURL: URL?
	var onSelectFile: (URL) -> Void

	@State private var searchText = ""
	@State private var selectedURL: URL?
	@FocusState private var isFocused: Bool
	@State private var eventMonitor: Any?

	private func moveSelection(up: Bool) {
		guard !filteredFiles.isEmpty else { return }
		if let current = selectedURL, let currentIndex = filteredFiles.firstIndex(where: { $0.url == current }) {
			if up {
				selectedURL = filteredFiles[(currentIndex - 1 + filteredFiles.count) % filteredFiles.count].url
			} else {
				selectedURL = filteredFiles[(currentIndex + 1) % filteredFiles.count].url
			}
		} else {
			selectedURL = up ? filteredFiles.last?.url : filteredFiles.first?.url
		}
	}

	private func installEventMonitor() {
		eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
			if event.keyCode == 126 {
				self.moveSelection(up: true)
				return nil
			}
			if event.keyCode == 125 {
				self.moveSelection(up: false)
				return nil
			}
			return event
		}
	}

	private func removeEventMonitor() {
		if let monitor = eventMonitor {
			NSEvent.removeMonitor(monitor)
			eventMonitor = nil
		}
	}

	private var flatFiles: [FlatFile] {
		flattenFileTree(files)
	}

	private var filteredFiles: [FlatFile] {
		let result = flatFiles.filter { !$0.name.hasSuffix("/") }
		if searchText.isEmpty {
			return result
		}
		return result.filter {
			$0.displayTitle.localizedCaseInsensitiveContains(searchText) || $0.name.localizedCaseInsensitiveContains(searchText)
		}
	}

	var body: some View {
		if workspaceDirectoryURL == nil {
			emptyBody(message: "No Workspace Open", detail: "Select a folder in the sidebar first")
		} else if flatFiles.isEmpty {
			emptyBody(message: "No Files Found", detail: "Add .org files to your workspace")
		} else {
			paletteBody
		}
	}

	private func emptyBody(message: String, detail: String) -> some View {
		VStack(spacing: 8) {
			Text(message)
				.font(.headline)
			Text(detail)
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.padding(40)
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
		.shadow(radius: 20)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.black.opacity(0.2))
		.onTapGesture { isPresented = false }
	}

	private var paletteBody: some View {
		VStack(spacing: 0) {
			HStack(spacing: 8) {
				Image(systemName: "magnifyingglass")
					.foregroundStyle(.secondary)
					.font(.title3)
				TextField("Search files…", text: $searchText)
					.textFieldStyle(.plain)
					.font(.title3)
					.focused($isFocused)
					.onSubmit { selectFile(selectedURL) }
			}
			.padding()
			.onAppear { isFocused = true }

			Divider()

			if filteredFiles.isEmpty {
				VStack(spacing: 8) {
					Text("No Matches")
						.font(.headline)
					Text("Try a different search term")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				.padding(40)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else {
				List(filteredFiles, id: \.url, selection: $selectedURL) { file in
					HStack(spacing: 6) {
						Image(systemName: "doc.text")
							.font(.caption)
							.foregroundStyle(.tertiary)
						Text(file.displayTitle)
							.fontWeight(.medium)
							.lineLimit(1)
						Text(file.name)
							.font(.caption)
							.foregroundStyle(.tertiary)
						if let dir = file.parentDir {
							Text(dir)
								.font(.caption)
								.foregroundStyle(.tertiary)
						}
						Spacer(minLength: 0)
					}
					.padding(.vertical, 2)
					.tag(file.url)
					.onTapGesture {
						selectedURL = file.url
						selectFile(file.url)
					}
				}
				.listStyle(.plain)
				.onAppear {
					selectedURL = filteredFiles.first?.url
				}
				.onChange(of: searchText) { _, _ in
					selectedURL = filteredFiles.first?.url
				}
			}
		}
		.onExitCommand { isPresented = false }
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
		.shadow(radius: 20)
		.frame(width: 440, height: 360)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.black.opacity(0.2))
		.onTapGesture { isPresented = false }
		.onAppear { installEventMonitor() }
		.onDisappear { removeEventMonitor() }
	}

	private func selectFile(_ url: URL?) {
		guard let url else { return }
		onSelectFile(url)
		isPresented = false
	}
}
