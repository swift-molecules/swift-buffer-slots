import Affine_Standard_Library_Integration
public import Buffer
public import Index
public import Memory_Allocator
public import Memory_Heap
import Ordinal_Standard_Library_Integration
public import Storage_Contiguous
public import Store_Split

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public init<M: BitwiseCopyable, E: ~Copyable>(
        capacity: Index<E>.Count,
        metadataInitial: M
    )
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>
        >
    {
        var lanes = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>.create(
            minimumCapacity: capacity.retag(M.self)
        )
        var slot: Index<M> = .zero
        let end = capacity.retag(M.self).map(Ordinal.init)
        while slot < end {
            lanes.initialize(at: slot, to: metadataInitial)
            slot += .one
        }
        self.init(
            header: Header(capacity: capacity),
            storage: Store.Split(
                lanes: lanes,
                elements: Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>.create(
                    minimumCapacity: capacity
                )
            )
        )
    }

    @inlinable
    public var capacity: Index<S.Element>.Count { header.capacity }
}
