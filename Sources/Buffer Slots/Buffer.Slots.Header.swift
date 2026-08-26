public import Buffer
public import Index

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
