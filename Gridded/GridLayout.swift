import Foundation
import CoreGraphics

struct GridLayout: Codable, Identifiable, Equatable {
  var id = UUID()
  var name: String
  // Zero means an equal share of the space left after fixed sizes.
  var columns: [Double]
  var rows: [Double]

  func resolve(in size: CGSize) -> ResolvedGrid? {
    guard let x = Self.boundaries(columns, extent: size.width),
      let y = Self.boundaries(rows, extent: size.height) else { return nil }
    return ResolvedGrid(x: x, y: y)
  }

  static func boundaries(_ sizes: [Double], extent: CGFloat) -> [CGFloat]? {
    guard (1...24).contains(sizes.count), extent.isFinite, extent > 0,
      sizes.allSatisfy({ $0.isFinite && $0 >= 0 }) else { return nil }
    let flexibleCount = sizes.filter { $0 == 0 }.count
    let remaining = extent - sizes.reduce(0, +)
    guard flexibleCount > 0, remaining >= CGFloat(flexibleCount) else { return nil }
    let share = remaining / CGFloat(flexibleCount)
    var result: [CGFloat] = [0]
    for size in sizes { result.append(result.last! + (size == 0 ? share : size)) }
    result[result.count - 1] = extent
    return result
  }

  // A layout may be used on a smaller display than the one it was created on.
  func resolvedOrEqual(in size: CGSize) -> ResolvedGrid {
    resolve(in: size) ?? GridLayout(
      name: name,
      columns: Array(repeating: 0, count: max(1, min(24, columns.count))),
      rows: Array(repeating: 0, count: max(1, min(24, rows.count)))
    ).resolve(in: size)!
  }
}

struct ResolvedGrid {
  let x: [CGFloat]
  // Row boundaries are measured down from the top of the workspace.
  let y: [CGFloat]

  func selection(start: CGPoint, end: CGPoint, in frame: CGRect) -> CGRect {
    func cell(_ value: CGFloat, boundaries: [CGFloat]) -> Int {
      min(boundaries.count - 2, max(0, (boundaries.firstIndex { $0 > value } ?? boundaries.count - 1) - 1))
    }
    let left = cell(min(start.x, end.x) - frame.minX, boundaries: x)
    let right = cell(max(start.x, end.x) - frame.minX, boundaries: x)
    let top = cell(frame.maxY - max(start.y, end.y), boundaries: y)
    let bottom = cell(frame.maxY - min(start.y, end.y), boundaries: y)
    return CGRect(x: frame.minX + x[left], y: frame.maxY - y[bottom + 1],
      width: x[right + 1] - x[left], height: y[bottom + 1] - y[top])
  }
}
