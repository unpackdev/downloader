// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

struct LinkedNode {
    bool inited;
    uint256 value;
    uint256 prev;
    uint256 next;
}

struct LinkedList {
    uint256 head;
    uint256 last;
    mapping(uint256 => LinkedNode) mem;
    uint256 it;
    uint256 length;
}

library LinkedListLib {
    function insert(
        LinkedList storage self,
        uint256 bearingPointer,
        uint256 value
    ) internal returns (uint256 pointer) {
        LinkedNode storage node = self.mem[bearingPointer];
        require(node.inited || bearingPointer == 0, "LinkedList insert: pointer out of scope");
        self.it += 1;
        LinkedNode storage newNode = self.mem[self.it];
        newNode.inited = true;
        newNode.value = value;
        newNode.prev = bearingPointer;
        newNode.next = bearingPointer == 0 ? self.head : node.next;
        node.next = self.it;
        self.mem[newNode.prev].next = self.it;
        self.mem[newNode.next].prev = self.it;
        if (bearingPointer == 0) self.head = self.it;
        if (bearingPointer == self.last) self.last = self.it;
        self.length += 1;
        return self.it;
    }

    function remove(LinkedList storage self, uint256 pointer) internal {
        LinkedNode storage node = self.mem[pointer];
        require(node.inited, "LinkedList remove: pointer out of scope");
        node.inited = false;
        self.mem[node.prev].next = node.next;
        self.mem[node.next].prev = node.prev;
        if (self.head == pointer) self.head = node.next;
        if (self.last == pointer) self.last = node.prev;
        self.length -= 1;
    }

    function get(LinkedList storage self, uint256 pointer) internal view returns (uint256 value) {
        LinkedNode storage node = self.mem[pointer];
        require(node.inited, "LinkedList get: pointer out of scope");
        return node.value;
    }

    function getNode(LinkedList storage self, uint256 pointer) internal view returns (LinkedNode memory) {
        LinkedNode storage node = self.mem[pointer];
        require(node.inited, "LinkedList getNode: pointer out of scope");
        return node;
    }
}
