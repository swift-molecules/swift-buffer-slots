public import Store
import Cardinal
import Ordinal
import Property
import Tagged
import Carrier
import Affine
public import Buffer
public import Cardinal
public import Index
public import Memory
public import Memory_Allocator
public import Memory_Small
public import Ordinal
public import Storage
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
        var slot: Index<E> = .zero
        let end = header.capacity.map { Ordinal($0.rawValue) }
        while slot < end {
            storage.initialize(at: slot, to: value)
            slot += .one
        }
        storage.elements.initialization = .empty
    }
}
