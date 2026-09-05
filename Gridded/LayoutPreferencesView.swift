import SwiftUI
import AppKit

struct LayoutPreferencesView: View {
  @EnvironmentObject private var config: Configuration
  @State private var draft = GridLayout(name: "", columns: [0], rows: [0])
  @State private var screenID: String = ""
  @State private var screens = NSScreen.screens

  private var screen: NSScreen? {
    screens.first { displayID($0) == screenID } ?? screens.first
  }
  private var workspace: CGSize { screen?.visibleFrame.size ?? CGSize(width: 1920, height: 1080) }
  private var valid: Bool {
    !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && draft.resolve(in: workspace) != nil
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Picker("Layout", selection: $config.activeLayoutID) {
            ForEach(config.layouts) { layout in Text(layout.name).tag(layout.id) }
          }
          .disabled(draft != config.activeLayout)
          Button("New") { addLayout(copy: false) }.disabled(draft != config.activeLayout)
          Button("Duplicate") { addLayout(copy: true) }.disabled(!valid)
          Button("Delete") {
            config.layouts.removeAll { $0.id == config.activeLayoutID }
            config.activeLayoutID = config.layouts[0].id
          }.disabled(config.layouts.count == 1 || draft != config.activeLayout)
        }
        TextField("Layout name", text: $draft.name)
        Picker("Preview display", selection: $screenID) {
          ForEach(screens, id: \.self) { screen in
            Text(screen.localizedName).tag(displayID(screen))
          }
        }
        Text("Usable workspace: \(Int(workspace.width)) × \(Int(workspace.height)) points")
          .font(.caption).foregroundStyle(.secondary)
        LayoutPreview(layout: draft, workspace: workspace)
          .frame(height: 150)
        HStack(alignment: .top, spacing: 24) {
          AxisEditor(title: "Columns · left to right", sizes: $draft.columns, extent: workspace.width, isHorizontal: true)
          AxisEditor(title: "Rows · top to bottom", sizes: $draft.rows, extent: workspace.height, isHorizontal: false)
        }
        Text("Equal share divides the remaining space equally after fixed sizes. Sizes use macOS points.")
          .font(.caption).foregroundStyle(.secondary)
        if !valid {
          Text("Enter a name, keep at least one Equal share per axis, and leave at least one point for each equal share. Fixed sizes must be positive.")
            .foregroundStyle(.red).font(.caption)
        }
        HStack {
          Button("Revert") { draft = config.activeLayout }
            .disabled(draft == config.activeLayout)
          Spacer()
          Button("Save Layout") {
            guard valid, let index = config.layouts.firstIndex(where: { $0.id == draft.id }) else { return }
            draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            config.layouts[index] = draft
          }.disabled(!valid || draft == config.activeLayout)
        }
        Text("Selecting a layout activates it. Save edits before switching layouts. On a display too small for the fixed sizes, snapping uses equal cells.")
          .font(.caption).foregroundStyle(.secondary)
        Text("Tip: drag across multiple cells to span them.")
          .font(.caption).foregroundStyle(.secondary)
      }.padding(20)
    }
    .onAppear { draft = config.activeLayout; screenID = screen.map(displayID) ?? "" }
    .onChange(of: config.activeLayoutID) { _, _ in draft = config.activeLayout }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
      screens = NSScreen.screens
      if !screens.contains(where: { displayID($0) == screenID }) {
        screenID = screens.first.map(displayID) ?? ""
      }
    }
  }

  private func displayID(_ screen: NSScreen) -> String {
    String(describing: screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] ?? screen.localizedName)
  }

  private func addLayout(copy: Bool) {
    var layout = copy ? draft : GridLayout(name: "New Layout", columns: [0, 0], rows: [0, 0])
    layout.id = UUID()
    if copy { layout.name += " Copy" }
    // Duplicate saved settings if the current draft is invalid.
    if layout.resolve(in: workspace) == nil {
      layout.columns = config.activeLayout.columns
      layout.rows = config.activeLayout.rows
    }
    config.layouts.append(layout)
    config.activeLayoutID = layout.id
    draft = layout
  }
}

private struct AxisEditor: View {
  let title: String
  @Binding var sizes: [Double]
  let extent: CGFloat
  let isHorizontal: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.headline)
      ForEach(sizes.indices, id: \.self) { index in
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("\(index + 1)").monospacedDigit()
            Picker("Sizing", selection: Binding(
              get: { sizes[index] != 0 },
              set: { sizes[index] = $0 ? 100 : 0 }
            )) {
              Text("Equal share").tag(false)
              Text("Fixed size").tag(true)
            }.labelsHidden()
            Button { sizes.swapAt(index, index - 1) } label: {
              Image(systemName: isHorizontal ? "arrow.left" : "arrow.up")
            }.disabled(index == 0).help(isHorizontal ? "Move left" : "Move up")
            .accessibilityLabel(isHorizontal ? "Move column left" : "Move row up")
            Button { sizes.swapAt(index, index + 1) } label: {
              Image(systemName: isHorizontal ? "arrow.right" : "arrow.down")
            }.disabled(index == sizes.count - 1).help(isHorizontal ? "Move right" : "Move down")
            .accessibilityLabel(isHorizontal ? "Move column right" : "Move row down")
            Button { sizes.remove(at: index) } label: {
              Image(systemName: "minus.circle")
            }.disabled(sizes.count == 1).help("Remove")
          }
          if sizes[index] != 0 {
            HStack {
              TextField("Size", value: Binding(
                get: { sizes[index] },
                set: { sizes[index] = max(1, $0) }
              ), format: .number)
                .textFieldStyle(.roundedBorder)
              Text("pt")
            }
          }
          if let edges = GridLayout.boundaries(sizes, extent: extent) {
            Text("\(Double(edges[index + 1] - edges[index]).formatted(.number.precision(.fractionLength(0...2)))) pt")
              .font(.caption).foregroundStyle(.secondary)
          }
        }
      }
      Button("Add") { sizes.append(0) }.disabled(sizes.count >= 24)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct LayoutPreview: View {
  let layout: GridLayout
  let workspace: CGSize

  var body: some View {
    GeometryReader { geometry in
      if let grid = layout.resolve(in: workspace) {
        let scale = max(0, min((geometry.size.width - 24) / workspace.width, (geometry.size.height - 24) / workspace.height))
        Path { path in
          let width = workspace.width * scale
          let height = workspace.height * scale
          for x in grid.x {
            path.move(to: CGPoint(x: x * scale, y: 0))
            path.addLine(to: CGPoint(x: x * scale, y: height))
          }
          for y in grid.y {
            path.move(to: CGPoint(x: 0, y: y * scale))
            path.addLine(to: CGPoint(x: width, y: y * scale))
          }
        }.stroke(Color.accentColor, lineWidth: 1)
        .frame(width: workspace.width * scale, height: workspace.height * scale)
        .background(Color.accentColor.opacity(0.08))
        .overlay(alignment: .topLeading) {
          GridAxisLabels(grid: grid, scale: scale)
        }
        .padding(.top, 24)
        .padding(.leading, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Text("Layout does not fit this workspace")
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

private struct GridAxisLabels: View {
  let grid: ResolvedGrid
  let scale: CGFloat

  var body: some View {
    ForEach(0..<(grid.x.count - 1), id: \.self) { column in
      let width = (grid.x[column + 1] - grid.x[column]) * scale
      label(column + 1)
        .frame(width: max(0, width - 2), height: 20)
        .clipped()
        .position(x: (grid.x[column] + grid.x[column + 1]) * scale / 2, y: -12)
        .accessibilityLabel("Column \(column + 1)")
    }
    ForEach(0..<(grid.y.count - 1), id: \.self) { row in
      let height = (grid.y[row + 1] - grid.y[row]) * scale
      label(row + 1)
        .frame(width: 20, height: max(0, height - 2))
        .clipped()
        .position(x: -12, y: (grid.y[row] + grid.y[row + 1]) * scale / 2)
        .accessibilityLabel("Row \(row + 1)")
    }
  }

  private func label(_ index: Int) -> some View {
    Text("\(index)")
      .font(.system(size: 12, weight: .medium, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(.primary)
      .lineLimit(1)
      .minimumScaleFactor(0.5)
  }
}
