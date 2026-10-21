public import Buffer
import Cardinal
import Carrier
import Ordinal
import Property
import Storage
public import Store
import Tagged

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
