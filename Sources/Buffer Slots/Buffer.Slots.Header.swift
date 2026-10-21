public import Buffer
public import Cardinal
import Carrier
import Ordinal
import Property
import Storage
public import Store
public import Tagged

extension Buffer.Slots where S: ~Copyable {

    @frozen
    public struct Header: Copyable, Sendable {

        public let capacity: Tagged<S.Element, Cardinal>

        @inlinable
        public init(capacity: Tagged<S.Element, Cardinal>) {
            self.capacity = capacity
        }
    }
}
