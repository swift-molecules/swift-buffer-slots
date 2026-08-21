public import Buffer_Primitive
import Memory_Allocator_Primitive
import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Store_Protocol_Primitives
import Store_Split_Primitives

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
