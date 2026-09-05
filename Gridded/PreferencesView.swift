//
//  PreferencesView.swift
//  Gridded
//
//  Created by An So on 2025-04-13.
//

import SwiftUI

struct PreferencesView: View {
  @ObservedObject var config = Configuration.shared

  @State private var showAlert: Bool = true

  var body: some View {
    TabView {
      ScrollView {
        VStack(spacing: 12) {
          GeneralSection()
          Divider()
          PermissionsSection()
          Divider()
          PreferenceSection()
          Divider()
          Picker("Active layout", selection: $config.activeLayoutID) {
            ForEach(config.layouts) { layout in
              Text(layout.name).tag(layout.id)
            }
          }
          .pickerStyle(.menu)
          .frame(maxWidth: 350)
        }.padding(20)
      }.tabItem { Text("General") }
      LayoutPreferencesView().tabItem { Text("Layouts") }
    }
    .frame(minWidth: 650, minHeight: 620)
    .environmentObject(Configuration.shared)
  }

  // MARK: - Section Components

  private struct GeneralSection: View {
    @EnvironmentObject private var config: Configuration

    var body: some View {
      VStack(spacing: 12) {
        Toggle(isOn: $config.autoStart) {
          Text("Auto start")
        }
      }
    }
  }

  private struct PermissionsSection: View {
    @EnvironmentObject private var config: Configuration

    var body: some View {
      VStack {
        if config.accessibilityPermission {
          Text("✅ Accessibility permission granted")
        } else {
          VStack {
            Text("❌ Accessibility permission not granted")
            Button("Grant permission") {
              let url = URL(
                string:
                  "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
              )!
              NSWorkspace.shared.open(url)
            }
            Button("Check permission again") {
              EventMonitor.shared.restart()
            }
            Text(
              "If the app is already in the list and granted permission but it still doesn't work, try removing the app from the list and restart the app."
            )
            .frame(width: 350)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
          }
        }
      }
    }
  }

  private struct PreferenceSection: View {
    @EnvironmentObject private var config: Configuration
    var body: some View {
      VStack {
        VStack {
          Text("Activate grid snapping when dragging a window by")
            .frame(width: 350)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
          HStack {
            Button("Secondary Mouse Click") {}.disabled(true)
            Text("or")
            Button("Space") {}.disabled(true)
          }
          Text("This will be customizable in the future.")
            .font(.footnote)
        }
        VStack {
          Toggle(isOn: $config.constrainMouse) {
            Text("Constrain mouse to active screen during snapping")
          }
          Text("Prevents the cursor from leaving the screen while moving windows.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(width: 350)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
        }
        VStack {
          Toggle(isOn: $config.moveOnActivate) {
            Text("Move and resize window while snapping (experimental)")
          }
          Text(
            "The window will be moved and resized immediately without waiting for mouse release."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(width: 350)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
        }
        VStack {
          Toggle(isOn: $config.requireWindowDragBeforeSnapping) {
            Text("Only allow snapping after the window has already moved")
          }
          Text(
            "When enabled, space or secondary click will only enter grid mode after the dragged window has actually changed position."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(width: 350)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
        }
        VStack {
          Toggle(isOn: $config.resetWindowOnEscape) {
            Text("Pressing Escape restores the original window frame")
          }
          Text(
            "Escape will move the window back to where it was when you grabbed it and will fully end the drag session until you release and grab the title bar again."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(width: 350)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
        }
      }
    }
  }

}
