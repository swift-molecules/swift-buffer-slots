public import Buffer
import Cardinal
import Carrier
import Ordinal
import Property
import Storage
public import Store
import Tagged
import Affine
public import Index
public import Memory
public import Memory_Allocator
public import Memory_Small

extension Buffer where S: Store.`Protocol`, S: ~Copyable {

    @frozen
    public struct Slots: ~Copyable {

        @usableFromInline
        var header: Header

        @usableFromInline
        var storage: S

        @inlinable
        package init(header: Header, storage: consuming S) {
            self.header = header
            self.storage = storage
        }
    }
}

extension Buffer.Slots: @unchecked Sendable where S: Sendable {}

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public subscript<M, E: ~Copyable>(metadata slot: Index<E>) -> M
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        get { storage.lanes[slot.retag(M.self)] }
        set { storage.lanes[slot.retag(M.self)] = newValue }
    }
}

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public mutating func initialize<M: BitwiseCopyable, E: ~Copyable>(
        to value: consuming E,
        at slot: Index<E>
    )
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        storage.initialize(at: slot, to: value)
        storage.elements.initialization = .empty
    }

    @inlinable
    public mutating func move<M: BitwiseCopyable, E: ~Copyable>(at slot: Index<E>) -> E
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        let element = storage.move(at: slot)
        storage.elements.initialization = .empty
        return element
    }

    @inlinable
    public mutating func deinitialize<M: BitwiseCopyable, E: ~Copyable>(at slot: Index<E>)
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        _ = storage.move(at: slot)
        storage.elements.initialization = .empty
    }
}

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public mutating func fill<M: BitwiseCopyable, E: ~Copyable>(metadata value: M)
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        var slot: Index<M> = .zero
        let end = header.capacity.retag(M.self).map { Ordinal($0.rawValue) }
        while slot < end {
            storage.lanes.initialize(at: slot, to: value)
            slot += .one
        }
    }

    @inlinable
    public mutating func deinitialize<M, E: ~Copyable>(where isOccupied: (M) -> Bool)
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        var slot: Index<E> = .zero
        let end = header.capacity.map { Ordinal($0.rawValue) }
        while slot < end {
            if isOccupied(storage.lanes[slot.retag(M.self)]) {
                _ = storage.move(at: slot)
            }
            slot += .one
        }
        storage.elements.initialization = .empty
    }
}

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public func withMetadataPointer<M: BitwiseCopyable, E: ~Copyable, R, Failure: Swift::Error>(
        _ body: (UnsafePointer<M>) throws(Failure) -> R
    ) throws(Failure) -> R
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        try storage.withLanes { lanes throws(Failure) -> R in
            let span = lanes.span
            return try span.withUnsafeBufferPointer { buffer throws(Failure) -> R in

                guard let base = buffer.baseAddress else {
                    preconditionFailure("Metadata lane span is non-empty and has a base address")
                }
                return try unsafe body(base)
            }
        }
    }

    @inlinable
    public mutating func withMutableMetadataPointer<
        M: BitwiseCopyable,
        E: ~Copyable,
        R,
        Failure: Swift::Error
    >(
        _ body: (UnsafeMutablePointer<M>) throws(Failure) -> R
    ) throws(Failure) -> R
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        try storage.withMutableLanes { lanes throws(Failure) -> R in
            var span = lanes.mutableSpan
            return try span.withUnsafeMutableBufferPointer { buffer throws(Failure) -> R in

                guard let base = buffer.baseAddress else {
                    preconditionFailure("Metadata lane span is non-empty and has a base address")
                }
                return try unsafe body(base)
            }
        }
    }
}

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public init<M: BitwiseCopyable, E: ~Copyable>(
        capacity: Tagged<E, Cardinal>,
        metadataInitial: M
    )
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        var lanes = Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>.create(
            minimumCapacity: capacity.retag(M.self)
        )
        var slot: Index<M> = .zero
        let end = capacity.retag(M.self).map { Ordinal($0.rawValue) }
        while slot < end {
            lanes.initialize(at: slot, to: metadataInitial)
            slot += .one
        }
        self.init(
            header: Header(capacity: capacity),
            storage: Store.Split(
                lanes: lanes,
                elements: Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>.create(
                    minimumCapacity: capacity
                )
            )
        )
    }

    @inlinable
    public var capacity: Tagged<S.Element, Cardinal> { header.capacity }
}
