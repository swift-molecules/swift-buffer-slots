public import Buffer_Primitive
public import Index_Primitives

extension Buffer.Slots where S: ~Copyable {

    @frozen
    public struct Header: Copyable, Sendable {

        public let capacity: Index<S.Element>.Count

        @inlinable
        public init(capacity: Index<S.Element>.Count) {
            self.capacity = capacity
        }
    }
}
