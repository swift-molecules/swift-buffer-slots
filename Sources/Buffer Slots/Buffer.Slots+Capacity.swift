import Affine_Standard_Library_Integration
public import Buffer
public import Cardinal
public import Index
public import Memory
public import Memory_Allocator_Primitive
public import Memory_Small
public import Ordinal
import Ordinal_Standard_Library_Integration
public import Storage
public import Storage_Memory
public import Store_Split
public import Tagged

extension Buffer.Slots where S: ~Copyable {

    @inlinable
    public init<M: BitwiseCopyable, E: ~Copyable>(
        capacity: Tagged<E, Cardinal>,
        metadataInitial: M
    )
    where
        S == Store.Split<
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>,
            Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>
        >
    {
        var lanes = Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<M>.create(
            minimumCapacity: capacity.retag(M.self)
        )
        var slot: Index<M> = .zero
        let end = capacity.retag(M.self).map { Ordinal($0.rawValue) }
        while slot < end {
            lanes.initialize(at: slot, to: metadataInitial)
            slot += .one
        }
        self.init(
            header: Header(capacity: capacity),
            storage: Store.Split(
                lanes: lanes,
                elements: Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<E>.create(
                    minimumCapacity: capacity
                )
            )
        )
    }

    @inlinable
    public var capacity: Tagged<S.Element, Cardinal> { header.capacity }
}
