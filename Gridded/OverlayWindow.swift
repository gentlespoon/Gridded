//
//  OverlayWindow.swift
//  Gridded
//
//  Created by An So on 2025-04-20.
//

import AppKit
import Foundation

class OverlayWindow: NSWindow {
  private var overlayView: OverlayView

  init(frame: CGRect, screen: NSScreen) {
    // Create overlay view with the screen's visible frame size
    overlayView = OverlayView(
      frame: NSRect(origin: .zero, size: screen.visibleFrame.size),
      highlightFrame: frame,
      screen: screen
    )

    super.init(
      contentRect: screen.visibleFrame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    // Configure window properties
    self.backgroundColor = .clear
    self.isOpaque = false
    self.hasShadow = false
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    self.ignoresMouseEvents = true

    // Set the overlay view as content view
    self.contentView = overlayView
  }

  func update(frame: CGRect, screen: NSScreen) {
    // Update the window to fit the screen
    self.setFrame(screen.visibleFrame, display: true)
    overlayView.frame = NSRect(origin: .zero, size: screen.visibleFrame.size)
    // Update the highlight frame
    overlayView.highlightFrame = frame
    overlayView.screen = screen
    overlayView.needsDisplay = true
  }
}

class OverlayView: NSView {
  private let fillColor = NSColor.systemBlue.withAlphaComponent(0.2)
  private let borderColor = NSColor.systemBlue.withAlphaComponent(0.5)
  private let gridColor = NSColor.systemBlue.withAlphaComponent(0.3)
  private let screenOverlayColor = NSColor.black.withAlphaComponent(0.1)
  private let borderWidth: CGFloat = 2.0

  var highlightFrame: CGRect
  var screen: NSScreen

  init(frame: NSRect, highlightFrame: CGRect, screen: NSScreen) {
    self.highlightFrame = highlightFrame
    self.screen = screen
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // Draw semi-transparent overlay for the entire screen
    screenOverlayColor.setFill()
    NSRect(origin: .zero, size: frame.size).fill()

    // Draw the grid for the entire screen
    drawGrid(in: bounds)

    // Convert highlight frame to view coordinates
    let highlightRect = convertHighlightFrameToViewCoordinates()

    // Draw the highlighted rectangle
    let path = NSBezierPath(
      roundedRect: highlightRect,
      xRadius: 4,
      yRadius: 4
    )

    fillColor.setFill()
    path.fill()

    borderColor.setStroke()
    path.lineWidth = borderWidth
    path.stroke()
  }

  private func convertHighlightFrameToViewCoordinates() -> NSRect {
    // Convert from global coordinates to screen-local coordinates
    let visibleFrame = screen.visibleFrame

    // Calculate the position relative to the screen's visible frame
    let relativeX = highlightFrame.origin.x - visibleFrame.origin.x

    // Y-coordinate conversion:
    let relativeY = highlightFrame.origin.y - visibleFrame.origin.y

    return NSRect(
      x: relativeX,
      y: relativeY,
      width: highlightFrame.width,
      height: highlightFrame.height
    )
  }

  private func drawGrid(in rect: NSRect) {
    let grid = Configuration.shared.activeLayout.resolvedOrEqual(in: rect.size)
    let gridPath = NSBezierPath()
    gridPath.lineWidth = 1
    for x in grid.x.dropFirst().dropLast() {
      gridPath.move(to: NSPoint(x: rect.minX + x, y: rect.minY))
      gridPath.line(to: NSPoint(x: rect.minX + x, y: rect.maxY))
    }
    for y in grid.y.dropFirst().dropLast() {
      gridPath.move(to: NSPoint(x: rect.minX, y: rect.maxY - y))
      gridPath.line(to: NSPoint(x: rect.maxX, y: rect.maxY - y))
    }
    gridColor.setStroke()
    gridPath.stroke()
  }
}
