public import Store
import Ordinal_Tagged
import Ordinal
import Ordinal_Cardinal
import Cardinal_Tagged
public import Buffer
public import Cardinal
import Storage
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
