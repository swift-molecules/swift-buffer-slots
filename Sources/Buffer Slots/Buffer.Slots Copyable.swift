import Affine
public import Buffer
import Cardinal
import Carrier
public import Index
public import Memory
public import Memory_Allocator
public import Memory_Small
import Ordinal
import Property
public import Storage
public import Store
public import Tagged

extension Buffer.Slots where S: ~Copyable, S.Element: Copyable {

    @inlinable
    public subscript(payload slot: Index<S.Element>) -> S.Element {
        get { storage[slot] }
        set { storage[slot] = newValue }
    }
}

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public mutating func fill<M: BitwiseCopyable, E: BitwiseCopyable>(payload value: E)
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        storage.elements.initialization = .empty
        storage.elements.withOutputSpan(addingCapacity: header.capacity) { span in
            span.append(repeating: value, count: span.freeCapacity)
        }
    }
}

extension Buffer.Slots where S: ~Copyable {

    /// A copy with its own storage, holding the same metadata and the same payload.
    ///
    /// Each plane is copied in one pass as far as it is initialised: the metadata always is, and the payload
    /// is once `fill(payload:)` has written every slot.
    @inlinable
    public borrowing func clone<M: BitwiseCopyable, E: BitwiseCopyable>() -> Self
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        Self(
            header: header,
            storage: Store.Split(lanes: storage.lanes.copy(), elements: storage.elements.copy())
        )
    }
}
