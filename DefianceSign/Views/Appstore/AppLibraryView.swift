//
//  AppLibraryView.swift
//  DefianceSign
//

import SwiftUI
import CoreData
import AltSourceKit
import NimbleViews

struct AppLibraryView: View {
	@StateObject private var _viewModel = SourcesViewModel.shared
	@State private var _isAddingSource = false
	@State private var _showOptionalSources = false

	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>

	private var _loadedAppCount: Int {
		_sources.reduce(0) { total, source in
			total + (_viewModel.sources[source]?.apps.count ?? 0)
		}
	}

	var body: some View {
		NavigationStack {
			Group {
				if _sources.isEmpty {
					_emptyNoSources
				} else if _viewModel.isFinished && _loadedAppCount == 0 {
					_emptyLoadingFailed
				} else {
					SourceAppsView(fromAppStore: true, object: Array(_sources), viewModel: _viewModel)
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Menu {
						Button("Add Custom Source", systemImage: "plus") {
							_isAddingSource = true
						}
						Button("Add DefianceSign Source", systemImage: "bolt.shield") {
							_addSource(DefianceSignConfig.altStoreRepo)
						}
						Divider()
						Button("Browse Community Sources…", systemImage: "square.stack.3d.up") {
							_showOptionalSources = true
						}
					} label: {
						Image(systemName: "ellipsis.circle")
					}
				}
			}
		}
		.navigationTitle("App Library")
		.task(id: Array(_sources)) {
			await _viewModel.fetchSources(_sources, refresh: _sources.count > 0)
		}
		.sheet(isPresented: $_isAddingSource) {
			SourcesAddView()
				.presentationDetents([.medium])
		}
		.sheet(isPresented: $_showOptionalSources) {
			_optionalSourcesSheet
		}
	}

	private var _optionalSourcesSheet: some View {
		NavigationStack {
			List(DefianceSignConfig.optionalLibrarySources) { source in
				Button {
					_addSource(source.url)
					_showOptionalSources = false
				} label: {
					VStack(alignment: .leading, spacing: 4) {
						Text(source.name)
							.font(.headline)
							.foregroundStyle(.primary)
						Text(source.description)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.padding(.vertical, 4)
				}
			}
			.navigationTitle("Community Sources")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close") { _showOptionalSources = false }
				}
			}
		}
		.presentationDetents([.medium, .large])
	}

	@ViewBuilder
	private var _emptyNoSources: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				Label("App Library", systemImage: "square.stack.3d.up.fill")
			} description: {
				Text("Add an AltStore source or pick a community repo from Ksign, Feather, and more.")
			} actions: {
				Button("Community Sources") { _showOptionalSources = true }
					.buttonStyle(.borderedProminent)
					.tint(.defianceAccent)
				Button("Add DefianceSign Source") { _addSource(DefianceSignConfig.altStoreRepo) }
				Button("Add Custom Source") { _isAddingSource = true }
			}
		} else {
			_emptyFallback(
				title: "App Library",
				message: "Add an AltStore source or pick a community repo from Ksign, Feather, and more.",
				actions: [
					("Community Sources", { _showOptionalSources = true }),
					("Add DefianceSign Source", { _addSource(DefianceSignConfig.altStoreRepo) }),
					("Add Custom Source", { _isAddingSource = true }),
				]
			)
		}
	}

	@ViewBuilder
	private var _emptyLoadingFailed: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				Label("No Apps Found", systemImage: "apps.iphone")
			} description: {
				Text("Sources were added but no apps loaded. Try a community source or refresh.")
			} actions: {
				Button("Community Sources") { _showOptionalSources = true }
					.buttonStyle(.borderedProminent)
					.tint(.defianceAccent)
				Button("Refresh") {
					Task { await _viewModel.fetchSources(_sources, refresh: true) }
				}
			}
		} else {
			_emptyFallback(
				title: "No Apps Found",
				message: "Sources were added but no apps loaded. Try a community source or refresh.",
				actions: [
					("Community Sources", { _showOptionalSources = true }),
					("Refresh", { Task { await _viewModel.fetchSources(_sources, refresh: true) } }),
				]
			)
		}
	}

	private func _emptyFallback(
		title: String,
		message: String,
		actions: [(String, () -> Void)]
	) -> some View {
		VStack(spacing: 16) {
			Image(systemName: "square.stack.3d.up.fill")
				.font(.system(size: 48))
				.foregroundStyle(.secondary)
			Text(title)
				.font(.title2.bold())
			Text(message)
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)
			ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
				Group {
					if index == 0 {
						Button(action.0, action: action.1)
							.buttonStyle(.borderedProminent)
							.tint(.defianceAccent)
					} else {
						Button(action.0, action: action.1)
							.buttonStyle(.bordered)
					}
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding()
		.navigationTitle("App Library")
	}

	private func _addSource(_ url: String) {
		FR.handleSource(url, silent: false) {
			Task { await _viewModel.fetchSources(_sources, refresh: true) }
		}
	}
}
