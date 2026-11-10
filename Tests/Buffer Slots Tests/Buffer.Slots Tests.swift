import Buffer
import Buffer_Slots
import Buffer_Slots_Test_Support
import Cardinal
import Index
import Memory
import Memory_Allocator
import Memory_Small
import Ordinal
import Property
import Storage
import Store
import Tagged
import Testing

private typealias Slots = Buffer<
    Store.Split<
        Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<UInt8>,
        Storage<Memory.Allocator<Memory.Small<0>>>.Contiguous<Int>
    >
>.Slots

private func capacity(_ rawValue: UInt) -> Tagged<Int, Cardinal> {
    Tagged(rawValue)
}

private func slot(_ rawValue: UInt) -> Index<Int> {
    Index(_unchecked: Ordinal(rawValue))
}

@Suite
struct `Buffer.Slots Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Buffer.Slots Tests`.Unit {

    @Test
    func `init creates buffer with requested capacity`() {
        let requestedCapacity = capacity(8)
        let buffer = Slots(capacity: requestedCapacity, metadataInitial: 0x80)
        #expect(buffer.capacity == requestedCapacity)
    }

    @Test
    func `metadata subscript reads initial value`() {
        let buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        #expect(buffer[metadata: slot(0)] == 0x80)
    }

    @Test
    func `metadata subscript writes and reads back`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer[metadata: slot(2)] = 0x42
        #expect(buffer[metadata: slot(2)] == 0x42)
    }

    @Test
    func `initialize and move round-trips element`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.initialize(to: 99, at: slot(1))
        let value = buffer.move(at: slot(1))
        #expect(value == 99)
    }

    @Test
    func `initialize and deinitialize does not crash`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.initialize(to: 42, at: slot(0))
        buffer.deinitialize(at: slot(0))
    }

    @Test
    func `payload subscript reads initialized element`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.initialize(to: 77, at: slot(2))
        #expect(buffer[payload: slot(2)] == 77)
        buffer.deinitialize(at: slot(2))
    }

    @Test
    func `payload subscript overwrites element`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.initialize(to: 10, at: slot(1))
        buffer[payload: slot(1)] = 20
        #expect(buffer[payload: slot(1)] == 20)
        buffer.deinitialize(at: slot(1))
    }

    @Test
    func `fill metadata overwrites all slots`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer[metadata: slot(0)] = 0x42
        buffer[metadata: slot(1)] = 0x43
        buffer.fill(metadata: 0xFF)
        #expect(buffer[metadata: slot(0)] == 0xFF)
        #expect(buffer[metadata: slot(1)] == 0xFF)
        #expect(buffer[metadata: slot(2)] == 0xFF)
        #expect(buffer[metadata: slot(3)] == 0xFF)
    }

    @Test
    func `fill payload writes all slots`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.fill(payload: 0)
        #expect(buffer[payload: slot(0)] == 0)
        #expect(buffer[payload: slot(1)] == 0)
        #expect(buffer[payload: slot(2)] == 0)
        #expect(buffer[payload: slot(3)] == 0)

        buffer.deinitialize(where: { _ in true })
    }

    @Test
    func `deinitialize where cleans up occupied slots`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)

        buffer.initialize(to: 10, at: slot(0))
        buffer[metadata: slot(0)] = 0x01
        buffer.initialize(to: 20, at: slot(2))
        buffer[metadata: slot(2)] = 0x02

        buffer.deinitialize(where: { $0 != 0x80 })
    }

    @Test
    func `withMetadataPointer provides contiguous access`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer[metadata: slot(1)] = 0x42
        buffer[metadata: slot(3)] = 0x43

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
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)

        unsafe buffer.withMutableMetadataPointer { ptr in
            unsafe ptr[0] = 0xAA
            unsafe ptr[1] = 0xBB
        }
        #expect(buffer[metadata: slot(0)] == 0xAA)
        #expect(buffer[metadata: slot(1)] == 0xBB)
    }

}

extension `Buffer.Slots Tests`.`Edge Case` {

    @Test
    func `all metadata initially uniform`() {
        let buffer = Slots(capacity: capacity(8), metadataInitial: 0x80)
        (UInt(0)..<8).forEach { i in
            #expect(buffer[metadata: slot(i)] == 0x80)
        }
    }

    @Test
    func `deinitialize where with no occupied slots is safe`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)

        buffer.deinitialize(where: { $0 != 0x80 })
    }

    @Test
    func `deinitialize where with all occupied slots`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x00)

        buffer.initialize(to: 1, at: slot(0))
        buffer.initialize(to: 2, at: slot(1))
        buffer.initialize(to: 3, at: slot(2))
        buffer.initialize(to: 4, at: slot(3))
        buffer.deinitialize(where: { $0 == 0x00 })
    }

    @Test
    func `fill metadata then selective overwrite`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.fill(metadata: 0xFF)
        buffer[metadata: slot(2)] = 0x42
        #expect(buffer[metadata: slot(0)] == 0xFF)
        #expect(buffer[metadata: slot(1)] == 0xFF)
        #expect(buffer[metadata: slot(2)] == 0x42)
        #expect(buffer[metadata: slot(3)] == 0xFF)
    }

    @Test
    func `move leaves slot uninitialized for reuse`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        let first = slot(0)

        buffer.initialize(to: 100, at: first)
        let moved = buffer.move(at: first)
        #expect(moved == 100)

        buffer.initialize(to: 200, at: first)
        let moved2 = buffer.move(at: first)
        #expect(moved2 == 200)
    }
}

extension `Buffer.Slots Tests`.Integration {

    @Test
    func `Swiss-table lifecycle — insert, probe, delete`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: capacity(8), metadataInitial: empty)

        let third = slot(3)
        buffer.initialize(to: 100, at: third)
        buffer[metadata: third] = 0x42

        #expect(buffer[metadata: third] == 0x42)
        #expect(buffer[payload: third] == 100)

        let removed = buffer.move(at: third)
        buffer[metadata: third] = empty
        #expect(removed == 100)
        #expect(buffer[metadata: third] == empty)
    }

    @Test
    func `multiple slots occupied simultaneously`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: capacity(8), metadataInitial: empty)

        let slots: [(Index<Int>, Int, UInt8)] = [
            (slot(0), 10, 0x01),
            (slot(2), 20, 0x02),
            (slot(5), 50, 0x05),
            (slot(7), 70, 0x07),
        ]
        for (slot, value, h2) in slots {
            buffer.initialize(to: value, at: slot)
            buffer[metadata: slot] = h2
        }

        for (slot, value, h2) in slots {
            #expect(buffer[metadata: slot] == h2)
            #expect(buffer[payload: slot] == value)
        }

        #expect(buffer[metadata: slot(1)] == empty)
        #expect(buffer[metadata: slot(3)] == empty)
        #expect(buffer[metadata: slot(4)] == empty)
        #expect(buffer[metadata: slot(6)] == empty)

        buffer.deinitialize(where: { $0 != empty })
    }

    @Test
    func `metadata scan via withMetadataPointer`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: capacity(8), metadataInitial: empty)
        buffer[metadata: slot(1)] = 0x42
        buffer[metadata: slot(4)] = 0x42
        buffer[metadata: slot(6)] = 0x42

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

extension `Buffer.Slots Tests`.Unit {

    @Test
    func `a new buffer holds the initial metadata in every slot`() {
        let buffer = Slots(capacity: capacity(5), metadataInitial: 0x5A)
        var metadata: [UInt8] = []
        (0..<5).forEach { position in
            metadata.append(buffer[metadata: slot(UInt(position))])
        }
        #expect(metadata == [0x5A, 0x5A, 0x5A, 0x5A, 0x5A])
    }

    @Test
    func `fill payload writes the value into every slot, and again over what is there`() {
        var buffer = Slots(capacity: capacity(5), metadataInitial: 0x80)
        buffer.fill(payload: 7)
        var first: [Int] = []
        (0..<5).forEach { position in
            first.append(buffer[payload: slot(UInt(position))])
        }
        #expect(first == [7, 7, 7, 7, 7])

        buffer[payload: slot(2)] = 99
        buffer.fill(payload: -3)
        var second: [Int] = []
        (0..<5).forEach { position in
            second.append(buffer[payload: slot(UInt(position))])
        }
        #expect(second == [-3, -3, -3, -3, -3])
    }

    @Test
    func `fill metadata writes every slot each time it is called`() {
        var buffer = Slots(capacity: capacity(5), metadataInitial: 0x80)
        buffer.fill(metadata: 0x11)
        buffer[metadata: slot(4)] = 0x42
        buffer.fill(metadata: 0x22)
        var metadata: [UInt8] = []
        (0..<5).forEach { position in
            metadata.append(buffer[metadata: slot(UInt(position))])
        }
        #expect(metadata == [0x22, 0x22, 0x22, 0x22, 0x22])
    }

    @Test
    func `clone holds the same metadata and payload in every slot`() {
        var buffer = Slots(capacity: capacity(4), metadataInitial: 0x80)
        buffer.fill(payload: 0)
        (0..<4).forEach { position in
            buffer[metadata: slot(UInt(position))] = UInt8(10 + position)
            buffer[payload: slot(UInt(position))] = 100 + position
        }

        let copy = buffer.clone()

        let copyCapacity = copy.capacity
        #expect(copyCapacity == capacity(4))
        var metadata: [UInt8] = []
        var payload: [Int] = []
        (0..<4).forEach { position in
            metadata.append(copy[metadata: slot(UInt(position))])
            payload.append(copy[payload: slot(UInt(position))])
        }
        #expect(metadata == [10, 11, 12, 13])
        #expect(payload == [100, 101, 102, 103])
    }

    @Test
    func `clone and original change apart`() {
        var buffer = Slots(capacity: capacity(2), metadataInitial: 0x80)
        buffer.fill(payload: 1)

        var copy = buffer.clone()
        copy[metadata: slot(0)] = 0x01
        copy[payload: slot(0)] = 50
        buffer[metadata: slot(1)] = 0x02
        buffer[payload: slot(1)] = 60

        let originalMetadata = [buffer[metadata: slot(0)], buffer[metadata: slot(1)]] as [UInt8]
        let originalPayload = [buffer[payload: slot(0)], buffer[payload: slot(1)]]
        let copyMetadata = [copy[metadata: slot(0)], copy[metadata: slot(1)]] as [UInt8]
        let copyPayload = [copy[payload: slot(0)], copy[payload: slot(1)]]
        #expect(originalMetadata == [0x80, 0x02])
        #expect(originalPayload == [1, 60])
        #expect(copyMetadata == [0x01, 0x80])
        #expect(copyPayload == [50, 1])
    }
}

extension `Buffer.Slots Tests`.`Edge Case` {

    @Test
    func `a buffer of no slots can be made, filled and cloned`() {
        var buffer = Slots(capacity: capacity(0), metadataInitial: 0x80)
        buffer.fill(metadata: 0x01)
        buffer.fill(payload: 1)
        let copy = buffer.clone()
        let copyCapacity = copy.capacity
        #expect(copyCapacity == capacity(0))
    }
}
