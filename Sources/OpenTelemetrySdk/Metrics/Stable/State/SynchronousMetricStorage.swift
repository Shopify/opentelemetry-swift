//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import OpenTelemetryApi

enum MetricStoreError: Error {
    case maxCardinality
}

typealias SynchronousMetricStorageProtocol = MetricStorage & WritableMetricStorage

public class SynchronousMetricStorage: SynchronousMetricStorageProtocol {
    let registeredReader: RegisteredReader
    public private(set) var metricDescriptor: MetricDescriptor
    let aggregatorTemporality: AggregationTemporality
    let aggregator: StableAggregator
    var aggregatorHandles = [[String: AttributeValue]: AggregatorHandle]()
    let attributeProcessor: AttributeProcessor
    var aggregatorHandlePool = [AggregatorHandle]()
	let storageLock = Lock()
    
    static func empty() -> SynchronousMetricStorageProtocol {
        return EmptyMetricStorage.instance
    }
    
    static func create(registeredReader: RegisteredReader,
                       registeredView: RegisteredView,
                       descriptor: InstrumentDescriptor,
                       exemplarFilter: ExemplarFilter) -> SynchronousMetricStorageProtocol
    {
        let metricDescriptor = MetricDescriptor(view: registeredView.view, instrument: descriptor)
        let aggregator = registeredView.view.aggregation.createAggregator(descriptor: descriptor, exemplarFilter: exemplarFilter)
        if type(of: aggregator) == DropAggregator.self {
            return empty()
        }
        
        return SynchronousMetricStorage(registeredReader: registeredReader, metricDescriptor: metricDescriptor, aggregator: aggregator, attributeProcessor: registeredView.attributeProcessor)
    }
    
    init(registeredReader: RegisteredReader, metricDescriptor: MetricDescriptor, aggregator: StableAggregator, attributeProcessor: AttributeProcessor) {
        self.registeredReader = registeredReader
        self.metricDescriptor = metricDescriptor
        self.aggregatorTemporality = registeredReader.reader.getAggregationTemporality(for: metricDescriptor.instrument.type)
        self.aggregator = aggregator
        self.attributeProcessor = attributeProcessor
    }
    
    private func getAggregatorHandle(attributes: [String: AttributeValue]) throws -> AggregatorHandle {
        let processedAttributes = attributeProcessor.process(incoming: attributes)
        if let handle = aggregatorHandles[processedAttributes] {
            return handle
        }
        if aggregatorHandles.count >= MetricStorageConstants.MAX_CARDINALITY {
            // error
            throw MetricStoreError.maxCardinality
        }
        
        let newHandle = aggregatorHandlePool.isEmpty ? aggregator.createHandle() : aggregatorHandlePool.remove(at: 0)
        if let existingHandle = aggregatorHandles[processedAttributes] {
            return existingHandle
        } else {
            aggregatorHandles[processedAttributes] = newHandle
            return newHandle
        }
    }
    
    public func collect(resource: Resource, scope: InstrumentationScopeInfo, startEpochNanos: UInt64, epochNanos: UInt64) -> StableMetricData {
		storageLock.lock()
		defer {
			storageLock.unlock()
		}
		
        let reset = aggregatorTemporality == .delta
        let start = reset ? registeredReader.lastCollectedEpochNanos : startEpochNanos
        
        var points = [PointData]()
        
		let keys = aggregatorHandles.keys
        aggregatorHandles.forEach { key, value in
            let point = value.aggregateThenMaybeReset(startEpochNano: start, endEpochNano: epochNanos, attributes: key, reset: reset)
            if reset {
                aggregatorHandlePool.append(value)
            }
            points.append(point)
        }
		if reset {
			for removeKey in keys {
				aggregatorHandles.removeValue(forKey: removeKey)
			}
		}
		
        if points.isEmpty {
            return StableMetricData.empty
        }
        return aggregator.toMetricData(resource: resource, scope: scope, descriptor: metricDescriptor, points: points, temporality: aggregatorTemporality)
    }
    
    public func isEmpty() -> Bool {
        false
    }
    
    public func recordLong(value: Int, attributes: [String: OpenTelemetryApi.AttributeValue]) {
		storageLock.lock()
		defer {
			storageLock.unlock()
		}
		
        do {
            let handle = try getAggregatorHandle(attributes: attributes)
            handle.recordLong(value: value, attributes: attributes)
        } catch MetricStoreError.maxCardinality {
            print("max cardinality (\(MetricStorageConstants.MAX_CARDINALITY)) reached for metric store. Discarding recorded value \"\(value)\" with attributes: \(attributes)")
        } catch {
            // TODO: record error
        }
    }
    
    public func recordDouble(value: Double, attributes: [String: OpenTelemetryApi.AttributeValue]) {
		storageLock.lock()
		defer {
			storageLock.unlock()
		}
		
        do {
            let handle = try getAggregatorHandle(attributes: attributes)
            handle.recordDouble(value: value, attributes: attributes)
        } catch MetricStoreError.maxCardinality {
            print("max cardinality (\(MetricStorageConstants.MAX_CARDINALITY)) reached for metric store. Discarding recorded value \"\(value)\" with attributes: \(attributes)")
        } catch {
            // TODO: error
        }
    }
}
