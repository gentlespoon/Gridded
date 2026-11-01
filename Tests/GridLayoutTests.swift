import Foundation
import CoreGraphics

@main
struct GridLayoutTests {
  static func main() throws {
    let layout = GridLayout(name: "Phone", columns: [0, 0, 906], rows: [0, 0])
    let grid = layout.resolve(in: CGSize(width: 3840, height: 2100))!
    assert(grid.x == [0, 1467, 2934, 3840])
    assert(grid.y == [0, 1050, 2100])
    assert(GridLayout.boundaries([0, 906], extent: 3840) == [0, 2934, 3840])
    assert(GridLayout.boundaries([906, 0], extent: 3840) == [0, 906, 3840])
    for invalid: [Double] in [[], [100], [0, -1], [0, .infinity], [0, .nan], [0, 3840], [0, 0, 3839]] {
      assert(GridLayout.boundaries(invalid, extent: 3840) == nil)
    }
    let frame = CGRect(x: -3840, y: 100, width: 3840, height: 2100)
    let start = CGPoint(x: -800, y: 2000)
    let end = CGPoint(x: -100, y: 1200)
    assert(grid.selection(start: start, end: end, in: frame) == CGRect(x: -906, y: 1150, width: 906, height: 1050))
    assert(grid.selection(start: end, end: start, in: frame) == grid.selection(start: start, end: end, in: frame))
    assert(grid.selection(start: CGPoint(x: -5000, y: 2500), end: CGPoint(x: 100, y: 0), in: frame) == frame)
    let asymmetric = GridLayout(name: "Rows", columns: [0], rows: [200, 0]).resolve(in: frame.size)!
    assert(asymmetric.selection(start: start, end: start, in: frame).height == 1900)
    let tiny = layout.resolvedOrEqual(in: CGSize(width: 600, height: 400))
    assert(tiny.x == [0, 200, 400, 600])
    let fractional = GridLayout.boundaries([0, 0, 0], extent: 1000)!
    assert(fractional.last == 1000)
    let data = try JSONEncoder().encode(layout)
    let decoded = try JSONDecoder().decode(GridLayout.self, from: data)
    assert(decoded == layout)
    print("Grid layout tests passed")
  }
}
