public import Store
import Cardinal
import Ordinal
import Property
import Tagged
import Carrier
public import Buffer
import Storage

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
