//
//  Persistence.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import CoreData

// MARK: - Class
final class Storage: ObservableObject {
	static let shared = Storage()
	let container: NSPersistentContainer
	
	private let _name: String = "Feather"
	
	init(inMemory: Bool = false) {
		container = NSPersistentContainer(name: _name)
		
		if inMemory {
			container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
		}
		
		if let description = container.persistentStoreDescriptions.first {
			description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
			description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
		}
		
		_loadStores(allowRecovery: true)
		
		container.viewContext.automaticallyMergesChangesFromParent = true
		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	}
	
	var context: NSManagedObjectContext {
		container.viewContext
	}
	
	func saveContext() {
		let ctx = context
		let persist = {
			guard ctx.hasChanges else { return }
			do {
				try ctx.save()
			} catch {
				print("Core Data save failed: \(error)")
				ctx.rollback()
			}
		}
		
		if Thread.isMainThread {
			persist()
		} else {
			DispatchQueue.main.sync(execute: persist)
		}
	}
	
	/// Runs Core Data mutations on the main-queue view context.
	/// iOS 16.1.x aborts when CertificatePair objects are inserted off-queue.
	func performOnContext(_ work: @escaping () -> Void) {
		if Thread.isMainThread {
			work()
		} else {
			DispatchQueue.main.sync(execute: work)
		}
	}
	
	func clearContext<T: NSManagedObject>(request: NSFetchRequest<T>) {
		performOnContext {
			let deleteRequest = NSBatchDeleteRequest(fetchRequest: (request as? NSFetchRequest<NSFetchRequestResult>)!)
			do {
				_ = try self.context.execute(deleteRequest)
			} catch {
				print("clear: \(error.localizedDescription)")
			}
		}
	}
	
	func countContent<T: NSManagedObject>(for type: T.Type) -> String {
		var result = "0"
		performOnContext {
			let request = T.fetchRequest()
			result = "\((try? self.context.count(for: request)) ?? 0)"
		}
		return result
	}
	
	private func _loadStores(allowRecovery: Bool) {
		container.loadPersistentStores { [weak self] storeDescription, error in
			guard let self else { return }
			guard error != nil else { return }
			
			print("Core Data store failed to load: \(String(describing: error))")
			guard allowRecovery else { return }
			
			self._destroyStore(storeDescription)
			self._loadStores(allowRecovery: false)
		}
	}
	
	private func _destroyStore(_ description: NSPersistentStoreDescription) {
		guard let url = description.url else { return }
		
		let coordinator = container.persistentStoreCoordinator
		try? coordinator.destroyPersistentStore(at: url, ofType: description.type, options: nil)
		
		let extras = [
			url,
			URL(fileURLWithPath: url.path + "-wal"),
			URL(fileURLWithPath: url.path + "-shm"),
		]
		for extra in extras {
			try? FileManager.default.removeItem(at: extra)
		}
	}
}
