import Affine_Standard_Library_Integration
public import Buffer
public import Index
public import Memory_Allocator
public import Memory_Heap
import Ordinal_Standard_Library_Integration
public import Storage_Contiguous
public import Store_Split

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
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        var slot: Index<E> = .zero
        let end = header.capacity.map(Ordinal.init)
        while slot < end {
            storage.initialize(at: slot, to: value)
            slot += .one
        }
        storage.elements.initialization = .empty
    }
}
