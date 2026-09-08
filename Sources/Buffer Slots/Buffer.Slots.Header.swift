public import Store
public import Ordinal_Tagged
public import Ordinal
public import Ordinal_Cardinal
public import Cardinal_Tagged
public import Buffer
public import Cardinal
public import Storage
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
