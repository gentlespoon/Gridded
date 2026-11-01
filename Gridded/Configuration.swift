//
//  Configuration.swift
//  Gridded
//
//  Created by An So on 2025-04-13.
//

import Combine
import Foundation
import Logging
import ServiceManagement

final class Configuration: ObservableObject {
  let logger = Logger(label: "Configuration")

  @Published var layouts: [GridLayout]
  @Published var activeLayoutID: UUID

  var activeLayout: GridLayout {
    layouts.first { $0.id == activeLayoutID } ?? layouts[0]
  }
  @Published var autoStart: Bool
  @Published var activateKey: Int
  @Published var constrainMouse: Bool
  @Published var moveOnActivate: Bool
  @Published var requireWindowDragBeforeSnapping: Bool
  @Published var resetWindowOnEscape: Bool
  @Published var accessibilityPermission: Bool = false

  static let shared = Configuration()

  private var cancellables = Set<AnyCancellable>()

  private init() {
    let defaults = UserDefaults.standard
    let migrated = GridLayout(name: "Default",
      columns: Array(repeating: 0, count: max(1, min(24, defaults.getValue(forKey: "gridColumns") ?? 3))),
      rows: Array(repeating: 0, count: max(1, min(24, defaults.getValue(forKey: "gridRows") ?? 3))))
    let saved = defaults.data(forKey: "gridLayouts").flatMap {
      try? JSONDecoder().decode([GridLayout].self, from: $0)
    }
    let initialLayouts = saved.flatMap { $0.isEmpty ? nil : $0 } ?? [migrated]
    layouts = initialLayouts
    let savedID = defaults.string(forKey: "activeLayoutID").flatMap(UUID.init(uuidString:))
    activeLayoutID = initialLayouts.first { $0.id == savedID }?.id ?? initialLayouts[0].id
    autoStart = defaults.getValue(forKey: "autoStart") ?? false
    activateKey = defaults.getValue(forKey: "activateKey") ?? 49
    constrainMouse = defaults.getValue(forKey: "constrainMouse") ?? true
    moveOnActivate = defaults.getValue(forKey: "moveOnActivate") ?? false
    requireWindowDragBeforeSnapping =
      defaults.getValue(forKey: "requireWindowDragBeforeSnapping") ?? true
    resetWindowOnEscape = defaults.getValue(forKey: "resetWindowOnEscape") ?? false

    $layouts
      .sink { if let data = try? JSONEncoder().encode($0) { defaults.set(data, forKey: "gridLayouts") } }
      .store(in: &cancellables)

    $activeLayoutID
      .sink { defaults.set($0.uuidString, forKey: "activeLayoutID") }
      .store(in: &cancellables)

    $autoStart
      .sink {
        defaults.set($0, forKey: "autoStart")
        self.setAutoStart($0)
      }
      .store(in: &cancellables)

    $activateKey
      .sink {
        defaults.set($0, forKey: "activateKey")
        if EventMonitor.shared.isMonitoring {
          EventMonitor.shared.restart()
        }
      }
      .store(in: &cancellables)

    $constrainMouse
      .sink { defaults.set($0, forKey: "constrainMouse") }
      .store(in: &cancellables)

    $moveOnActivate
      .sink { defaults.set($0, forKey: "moveOnActivate") }
      .store(in: &cancellables)

    $requireWindowDragBeforeSnapping
      .sink { defaults.set($0, forKey: "requireWindowDragBeforeSnapping") }
      .store(in: &cancellables)

    $resetWindowOnEscape
      .sink { defaults.set($0, forKey: "resetWindowOnEscape") }
      .store(in: &cancellables)

    if defaults.object(forKey: "autoStart") == nil {
      autoStart = true
    }
  }

  private func setAutoStart(_ start: Bool) {
    do {
      if start {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
    } catch {
      logger.warning("Failed to register auto start: \(error)")
    }
  }
}

// Extension to check if a key exists in UserDefaults
extension UserDefaults {
  func getValue<T>(forKey key: String) -> T? {
    return object(forKey: key) as? T
  }
}
