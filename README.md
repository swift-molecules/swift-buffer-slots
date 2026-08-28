# Buffer Slots

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The **slots buffer discipline** over the `Buffer` namespace: a fixed-capacity, metadata-parametric
slots buffer backed by split storage, with consumer-managed element lifecycle — the substrate a
Swiss-table hash map builds on. Supports noncopyable (`~Copyable`) elements.

`Buffer.Slots` is one buffer discipline among siblings; linear, ring, slab, linked, and arena
each live in their own package.

---

## Quick Start

`Buffer.Slots` performs no element-lifecycle tracking of its own — the metadata array *is* the
occupancy state, and the consumer decides what each metadata value means. That makes it the right
substrate for open-addressed hash tables, where the control bytes and the payloads must sit in one
allocation.

```swift
import Buffer_Slots
import Cardinal
import Index
import Tagged

// `Buffer.Slots` is generic over its dual-plane split substrate. The canonical tower carries
// `Int` payloads behind `UInt8` control bytes — the Swiss-table shape. Alias it for readability.
typealias Table = Buffer<
    Store.Split<
        Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<UInt8>,
        Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<Int>
    >
>.Slots

// 8 slots, metadata byte 0x80 = "empty" (the Swiss-table convention).
let empty: UInt8 = 0x80
var table = Table(capacity: Tagged<Int, Cardinal>(8), metadataInitial: empty)

// Insert: write the payload, then mark the slot occupied with its h2 hash byte.
let slot = Index<Int>(3)
table.initialize(to: 100, at: slot)
table[metadata: slot] = 0x42

// Probe: read the payload (or scan the contiguous metadata array for SIMD matching).
let value = table[payload: slot]          // 100

// Delete: move the payload out, mark the slot empty again.
let removed = table.move(at: slot)        // 100
table[metadata: slot] = empty

// Before dropping a buffer with initialized elements, deinitialize the occupied slots.
table.deinitialize(where: { $0 != empty })
```

`Buffer.Slots` is generic over both its element type (including noncopyable elements) and a
`BitwiseCopyable` metadata type — typically `UInt8` for a Swiss-table control byte. It is
fixed-capacity: growth is a consumer concern (allocate a larger buffer and re-insert).

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-molecules/swift-buffer-slots.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Buffer Slots", package: "swift-buffer-slots"),
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3.1
and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux toolchain).

---

## Architecture

`Buffer.Slots` ships as one module containing the value type and every operation that touches its
storage. Slots is single-variant and carries no `Copyable`-imposing conformance, so — unlike the
multi-variant disciplines — it needs no separate conformance module.

| Product | Target | Purpose |
|---------|--------|---------|
| `Buffer Slots` | `Sources/Buffer Slots/` | The `Buffer.Slots` value type plus its capacity initializer, metadata and payload subscripts, element-lifecycle operations (`initialize` / `move` / `deinitialize`), bulk fills, and the `withMetadataPointer` SIMD escape hatch. |
| `Buffer Slots Test Support` | `Tests/Support/` | Re-exports the package for test consumers. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Related Packages

- [`swift-buffer`](https://github.com/swift-atoms/swift-buffer) — the `Buffer` namespace and capacity-growth vocabulary.
- [`swift-storage-split`](https://github.com/swift-molecules/swift-storage-split) — the split storage substrate (metadata + element dual arrays in one allocation).
- Sibling disciplines: `swift-buffer-linear`, `swift-buffer-ring`, `swift-buffer-slab`, `swift-buffer-linked`, `swift-buffer-arena`.

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
