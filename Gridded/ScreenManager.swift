//
//  ScreenManager.swift
//  Gridded
//
//  Created by An So on 2025-04-20.
//

import Cocoa
import Logging

class ScreenManager {
  static let shared = ScreenManager()
  private let logger = Logger(label: "ScreenManager")

  private init() {}

  public func getActiveScreen() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    return getScreen(at: mouseLocation)
  }

  public func getScreen(at point: CGPoint) -> NSScreen? {
    for screen in NSScreen.screens {
      if screen.frame.contains(point) {
        return screen
      }
    }
    return nil
  }

  public func virtualDesktopFrame() -> CGRect {
    return NSScreen.screens.reduce(CGRect.null) { partialResult, screen in
      partialResult.union(screen.frame)
    }
  }

  public func cocoaPointToQuartz(_ point: CGPoint) -> CGPoint {
    let desktopFrame = virtualDesktopFrame()
    return CGPoint(x: point.x, y: desktopFrame.maxY - point.y)
  }

  public func getScreenPadding(screen: NSScreen) -> (
    top: CGFloat, bottom: CGFloat, right: CGFloat, left: CGFloat
  ) {
    let visibleFrame = screen.visibleFrame
    let screenFrame = screen.frame

    let paddingLeft = visibleFrame.minX - screenFrame.minX
    let paddingRight = screenFrame.maxX - visibleFrame.maxX
    let paddingTop = screenFrame.maxY - visibleFrame.maxY
    let paddingBottom = visibleFrame.minY - screenFrame.minY
    return (top: paddingTop, bottom: paddingBottom, right: paddingRight, left: paddingLeft)
  }

  public func convertCoordinates(
    coords: (start: CGPoint, end: CGPoint),
    screen: NSScreen
  ) -> CGRect {
    Configuration.shared.activeLayout.resolvedOrEqual(in: screen.visibleFrame.size)
      .selection(start: coords.start, end: coords.end, in: screen.visibleFrame)
  }
}
