public import Buffer
import Memory_Allocator
import Memory_Heap
public import Storage_Contiguous
public import Store_Protocol
import Store_Split

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
