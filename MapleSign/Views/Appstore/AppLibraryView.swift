//
//  AppLibraryView.swift
//  MapleSign
//

import SwiftUI
import CoreData
import AltSourceKit
import NimbleViews

struct AppLibraryView: View {
	@StateObject private var _viewModel = SourcesViewModel.shared
	@State private var _isAddingSource = false

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
			.navigationTitle("App Library")
			.safeAreaInset(edge: .top) {
				VStack(spacing: 8) {
					MapleSignBrandHeader(
						subtitle: _sources.isEmpty
							? "Add a source to browse apps"
							: "\(_loadedAppCount) apps from \(_sources.count) source\(_sources.count == 1 ? "" : "s")",
						compact: true
					)
					.padding(.horizontal)

					if !_sources.isEmpty {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								ForEach(_sources, id: \.identifier) { source in
									_sourceChip(source)
								}
								Button {
									_isAddingSource = true
								} label: {
									Label("Add Source", systemImage: "plus.circle.fill")
										.font(.caption.weight(.semibold))
										.padding(.horizontal, 12)
										.padding(.vertical, 6)
										.background(Color.mapleAccent.opacity(0.15))
										.foregroundStyle(Color.mapleAccent)
										.clipShape(Capsule())
								}
							}
							.padding(.horizontal)
						}
					}
				}
				.padding(.bottom, 8)
				.background(.ultraThinMaterial)
			}
		}
		.task(id: Array(_sources)) {
			await _viewModel.fetchSources(_sources, refresh: _sources.count > 0)
		}
		.sheet(isPresented: $_isAddingSource) {
			SourcesAddView()
				.presentationDetents([.medium])
		}
	}

	@ViewBuilder
	private func _sourceChip(_ source: AltSource) -> some View {
		let count = _viewModel.sources[source]?.apps.count ?? 0
		HStack(spacing: 4) {
			Text(source.name ?? "Source")
				.lineLimit(1)
			Text("\(count)")
				.font(.caption2.weight(.bold))
				.padding(.horizontal, 5)
				.padding(.vertical, 2)
				.background(Color.mapleAccent.opacity(0.2))
				.clipShape(Capsule())
		}
		.font(.caption.weight(.medium))
		.padding(.horizontal, 10)
		.padding(.vertical, 6)
		.background(Color(uiColor: .tertiarySystemFill))
		.clipShape(Capsule())
	}

	@ViewBuilder
	private var _emptyNoSources: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				Label("App Library", systemImage: "square.stack.3d.up.fill")
			} description: {
				Text("Add an AltStore source to browse and download IPA apps.")
			} actions: {
				Button("Add Source") { _isAddingSource = true }
					.buttonStyle(.borderedProminent)
					.tint(.mapleAccent)
				Button("Add MapleSign Source") { _addBuiltInSource() }
			}
		} else {
			_emptyFallback(
				title: "App Library",
				message: "Add an AltStore source to browse and download IPA apps.",
				primary: ("Add Source", { _isAddingSource = true }),
				secondary: ("Add MapleSign Source", _addBuiltInSource)
			)
		}
	}

	@ViewBuilder
	private var _emptyLoadingFailed: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				Label("No Apps Found", systemImage: "apps.iphone")
			} description: {
				Text("Sources were added but no apps loaded. Check your connection and refresh.")
			} actions: {
				Button("Refresh") {
					Task { await _viewModel.fetchSources(_sources, refresh: true) }
				}
				.buttonStyle(.borderedProminent)
				.tint(.mapleAccent)
			}
		} else {
			_emptyFallback(
				title: "No Apps Found",
				message: "Sources were added but no apps loaded. Check your connection and refresh.",
				primary: ("Refresh", {
					Task { await _viewModel.fetchSources(_sources, refresh: true) }
				}),
				secondary: nil
			)
		}
	}

	private func _emptyFallback(
		title: String,
		message: String,
		primary: (String, () -> Void),
		secondary: (String, () -> Void)?
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
			Button(primary.0, action: primary.1)
				.buttonStyle(.borderedProminent)
				.tint(.mapleAccent)
			if let secondary {
				Button(secondary.0, action: secondary.1)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding()
	}

	private func _addBuiltInSource() {
		FR.handleSource(MapleSignConfig.altStoreRepo, silent: false) {
			Task { await _viewModel.fetchSources(_sources, refresh: true) }
		}
	}
}
