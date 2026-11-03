# swift-buffer-slots

Use this package when you build an open-addressing structure, such as a Swiss-style hash table, and need a fixed number of slots where each slot has a payload and a small `BitwiseCopyable` metadata value, kept in two separate contiguous lanes so you can scan the metadata without touching the payloads. Start from `Buffer.Slots`. It records nothing about which slots are occupied: your metadata does that. If you want the buffer to track occupancy and clean up live elements for you, use Buffer.Slab from the sibling package swift-buffer-slab instead.

## Laws

- Every metadata entry below `capacity` always holds a value. `init(capacity:metadataInitial:)` writes `metadataInitial` into every one of them, and `fill(metadata:)` overwrites all of them without touching any payload.
- `capacity` is exactly the capacity you asked for, even if the allocator returns more memory. Metadata access, fills and `deinitialize(where:)` only cover the first `capacity` slots.
- Payload slots begin uninitialized, and the buffer never records which ones are initialized. Reading, moving or deinitializing a payload slot that holds no value is undefined.
- No payload operation changes metadata. After `move(at:)` or `deinitialize(at:)` the slot's metadata is unchanged, so the caller resets it to its "empty" value.
- `Buffer.Slots` has no deinitializer for payloads. Dropping the buffer deinitializes no element. Call `deinitialize(where:)` first, with a predicate that is true for exactly the occupied slots. It deinitializes the payload of each slot in the first `capacity` slots whose metadata satisfies the predicate, in index order, and leaves the metadata as it was.
- `fill(payload:)` initializes every payload slot in the first `capacity` slots without deinitializing what was there. It exists only for `BitwiseCopyable` payloads, where nothing is lost. Afterwards every slot counts as occupied for cleanup.
- The pointers from `withMetadataPointer` and `withMutableMetadataPointer` address `capacity` contiguous metadata entries in slot order, and are valid only inside the closure.
