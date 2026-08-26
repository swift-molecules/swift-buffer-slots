import Affine_Standard_Library_Integration
public import Buffer
public import Index
public import Memory_Allocator
public import Memory_Heap
import Ordinal_Standard_Library_Integration
public import Storage_Contiguous
public import Store_Split

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public subscript<M, E: ~Copyable>(metadata slot: Index<E>) -> M
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
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
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        storage.initialize(at: slot, to: value)
        storage.elements.initialization = .empty
    }

    @inlinable
    public mutating func move<M: BitwiseCopyable, E: ~Copyable>(at slot: Index<E>) -> E
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
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
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
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
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        var slot: Index<M> = .zero
        let end = header.capacity.retag(M.self).map(Ordinal.init)
        while slot < end {
            storage.lanes.initialize(at: slot, to: value)
            slot += .one
        }
    }

    @inlinable
    public mutating func deinitialize<M, E: ~Copyable>(where isOccupied: (M) -> Bool)
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        var slot: Index<E> = .zero
        let end = header.capacity.map(Ordinal.init)
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
    public func withMetadataPointer<M: BitwiseCopyable, E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (UnsafePointer<M>) throws(Failure) -> R
    ) throws(Failure) -> R
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        try storage.withLanes { lanes throws(Failure) -> R in
            let span = lanes.span
            return try span.withUnsafeBufferPointer { buffer throws(Failure) -> R in

                try unsafe body(buffer.baseAddress!)
            }
        }
    }

    @inlinable
    public mutating func withMutableMetadataPointer<
        M: BitwiseCopyable,
        E: ~Copyable,
        R,
        Failure: Swift.Error
    >(
        _ body: (UnsafeMutablePointer<M>) throws(Failure) -> R
    ) throws(Failure) -> R
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        try storage.withMutableLanes { lanes throws(Failure) -> R in
            var span = lanes.mutableSpan
            return try span.withUnsafeMutableBufferPointer { buffer throws(Failure) -> R in

                try unsafe body(buffer.baseAddress!)
            }
        }
    }
}
