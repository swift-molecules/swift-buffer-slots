public import Store_Initialization
public import Ordinal_Tagged
public import Ordinal_Protocol
public import Ordinal_Cardinal
public import Cardinal_Tagged
public import Cardinal_Carrier
import Affine_Standard_Library_Integration
public import Buffer
public import Cardinal
public import Index
public import Memory
public import Memory_Allocator
public import Memory_Small
public import Ordinal
import Ordinal_Standard_Library_Integration
public import Storage
public import Store
public import Store_Protocol
public import Storage_Memory
public import Store_Split
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
