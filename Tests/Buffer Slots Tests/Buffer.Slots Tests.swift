import Buffer
import Buffer_Slots
import Buffer_Slots_Test_Support
import Storage_Contiguous
import Store_Split
import Testing

private typealias Slots = Buffer<
    Store.Split<
        Storage<Memory.Allocator<Memory.Heap>>.Contiguous<UInt8>,
        Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>
    >
>.Slots

@Suite
struct `Buffer.Slots Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Buffer.Slots Tests`.Unit {

    @Test
    func `init creates buffer with requested capacity`() {
        let capacity: Index<Int>.Count = 8
        let buffer = Slots(capacity: capacity, metadataInitial: 0x80)
        #expect(buffer.capacity == capacity)
    }

    @Test
    func `metadata subscript reads initial value`() {
        let buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 0
        #expect(buffer[metadata: slot] == 0x80)
    }

    @Test
    func `metadata subscript writes and reads back`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 2
        buffer[metadata: slot] = 0x42
        #expect(buffer[metadata: slot] == 0x42)
    }

    @Test
    func `initialize and move round-trips element`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 1
        buffer.initialize(to: 99, at: slot)
        let value = buffer.move(at: slot)
        #expect(value == 99)
    }

    @Test
    func `initialize and deinitialize does not crash`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 0
        buffer.initialize(to: 42, at: slot)
        buffer.deinitialize(at: slot)
    }

    @Test
    func `payload subscript reads initialized element`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 2
        buffer.initialize(to: 77, at: slot)
        #expect(buffer[payload: slot] == 77)
        buffer.deinitialize(at: slot)
    }

    @Test
    func `payload subscript overwrites element`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 1
        buffer.initialize(to: 10, at: slot)
        buffer[payload: slot] = 20
        #expect(buffer[payload: slot] == 20)
        buffer.deinitialize(at: slot)
    }

    @Test
    func `fill metadata overwrites all slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer[metadata: 0] = 0x42
        buffer[metadata: 1] = 0x43
        buffer.fill(metadata: 0xFF)
        #expect(buffer[metadata: 0] == 0xFF)
        #expect(buffer[metadata: 1] == 0xFF)
        #expect(buffer[metadata: 2] == 0xFF)
        #expect(buffer[metadata: 3] == 0xFF)
    }

    @Test
    func `fill payload writes all slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer.fill(payload: 0)
        #expect(buffer[payload: 0] == 0)
        #expect(buffer[payload: 1] == 0)
        #expect(buffer[payload: 2] == 0)
        #expect(buffer[payload: 3] == 0)

        buffer.deinitialize(where: { _ in true })
    }

    @Test
    func `deinitialize where cleans up occupied slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)

        buffer.initialize(to: 10, at: 0)
        buffer[metadata: 0] = 0x01
        buffer.initialize(to: 20, at: 2)
        buffer[metadata: 2] = 0x02

        buffer.deinitialize(where: { $0 != 0x80 })
    }

    @Test
    func `withMetadataPointer provides contiguous access`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer[metadata: 1] = 0x42
        buffer[metadata: 3] = 0x43

        let result = unsafe buffer.withMetadataPointer { ptr in
            (unsafe ptr[0], unsafe ptr[1], unsafe ptr[2], unsafe ptr[3])
        }
        #expect(result.0 == 0x80)
        #expect(result.1 == 0x42)
        #expect(result.2 == 0x80)
        #expect(result.3 == 0x43)
    }

    @Test
    func `withMutableMetadataPointer allows mutation`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)

        unsafe buffer.withMutableMetadataPointer { ptr in
            unsafe ptr[0] = 0xAA
            unsafe ptr[1] = 0xBB
        }
        #expect(buffer[metadata: 0] == 0xAA)
        #expect(buffer[metadata: 1] == 0xBB)
    }

}

extension `Buffer.Slots Tests`.`Edge Case` {

    @Test
    func `all metadata initially uniform`() {
        let buffer = Slots(capacity: 8, metadataInitial: 0x80)
        (UInt(0)..<8).forEach { i in
            let slot = Index<Int>(_unchecked: Ordinal(i))
            #expect(buffer[metadata: slot] == 0x80)
        }
    }

    @Test
    func `deinitialize where with no occupied slots is safe`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)

        buffer.deinitialize(where: { $0 != 0x80 })
    }

    @Test
    func `deinitialize where with all occupied slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x00)

        buffer.initialize(to: 1, at: 0)
        buffer.initialize(to: 2, at: 1)
        buffer.initialize(to: 3, at: 2)
        buffer.initialize(to: 4, at: 3)
        buffer.deinitialize(where: { $0 == 0x00 })
    }

    @Test
    func `fill metadata then selective overwrite`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer.fill(metadata: 0xFF)
        buffer[metadata: 2] = 0x42
        #expect(buffer[metadata: 0] == 0xFF)
        #expect(buffer[metadata: 1] == 0xFF)
        #expect(buffer[metadata: 2] == 0x42)
        #expect(buffer[metadata: 3] == 0xFF)
    }

    @Test
    func `move leaves slot uninitialized for reuse`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 0

        buffer.initialize(to: 100, at: slot)
        let moved = buffer.move(at: slot)
        #expect(moved == 100)

        buffer.initialize(to: 200, at: slot)
        let moved2 = buffer.move(at: slot)
        #expect(moved2 == 200)
    }
}

extension `Buffer.Slots Tests`.Integration {

    @Test
    func `Swiss-table lifecycle — insert, probe, delete`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: 8, metadataInitial: empty)

        let slot: Index<Int> = 3
        buffer.initialize(to: 100, at: slot)
        buffer[metadata: slot] = 0x42

        #expect(buffer[metadata: slot] == 0x42)
        #expect(buffer[payload: slot] == 100)

        let removed = buffer.move(at: slot)
        buffer[metadata: slot] = empty
        #expect(removed == 100)
        #expect(buffer[metadata: slot] == empty)
    }

    @Test
    func `multiple slots occupied simultaneously`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: 8, metadataInitial: empty)

        let slots: [(Index<Int>, Int, UInt8)] = [
            (0, 10, 0x01),
            (2, 20, 0x02),
            (5, 50, 0x05),
            (7, 70, 0x07),
        ]
        for (slot, value, h2) in slots {
            buffer.initialize(to: value, at: slot)
            buffer[metadata: slot] = h2
        }

        for (slot, value, h2) in slots {
            #expect(buffer[metadata: slot] == h2)
            #expect(buffer[payload: slot] == value)
        }

        #expect(buffer[metadata: 1] == empty)
        #expect(buffer[metadata: 3] == empty)
        #expect(buffer[metadata: 4] == empty)
        #expect(buffer[metadata: 6] == empty)

        buffer.deinitialize(where: { $0 != empty })
    }

    @Test
    func `metadata scan via withMetadataPointer`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: 8, metadataInitial: empty)
        buffer[metadata: 1] = 0x42
        buffer[metadata: 4] = 0x42
        buffer[metadata: 6] = 0x42

        let matches = unsafe buffer.withMetadataPointer { ptr in
            var result: [Int] = []
            (0..<8).forEach { i in
                if unsafe ptr[i] == 0x42 {
                    result.append(i)
                }
            }
            return result
        }
        #expect(matches == [1, 4, 6])
    }
}
