// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeMath.sol";

library OrderStatisticsTreeLib {
    uint8 private constant EMPTY = 0;

    struct Node {
        uint parent;
        uint left;
        uint right;
        uint count;
        bool red;
        uint16[] keys;
    }

    struct Tree {
        uint root;
        uint8 minLength; // tracking minLength assigned so far
        mapping(uint => Node) nodes;
    }

    function exists(Tree storage self, uint value) public view returns (bool _exists) {
        if (value == EMPTY) return false;
        if (value == self.root) return true;
        if (self.nodes[value].parent != EMPTY) return true;
        return false;
    }

    function getNodeCount(Tree storage self, uint value) public view returns(uint count_) {
        Node storage gn = self.nodes[value];
        return gn.keys.length + gn.count;
    }

    function count(Tree storage self) public view returns(uint _count) {
        return getNodeCount(self, self.root);
    }

    function rank(Tree storage self, uint value) private view returns(uint _rank) {
        _rank = 0;
        if (count(self) > 0) {
            bool finished = false;
            uint cursor = self.root;
            Node storage c = self.nodes[cursor];
            uint smaller = getNodeCount(self, c.left);
            while (!finished) {
                uint keyCount = uint(c.keys.length);
                if (cursor == value) {
                    finished = true;
                } else {
                    if (cursor < value) {
                        cursor = c.right;
                        c = self.nodes[cursor];
                        smaller += keyCount + getNodeCount(self, c.left);
                    } else {
                        cursor = c.left;
                        c = self.nodes[cursor];
                        uint nodeCount = getNodeCount(self, c.right);
                        uint sum = SafeMath.add(keyCount, nodeCount);
                        if (sum >= smaller) {
                            smaller = 0;
                        } else {
                            smaller = SafeMath.sub(smaller, sum);
                        }
                    }
                }
                if (!exists(self, cursor)) {
                    finished = true;
                }
            }
            _rank = smaller + 1;
        }
    }

    function insertCock(Tree storage self, uint16 newTokenId, uint balance) public returns(uint8) {
        insert(self, newTokenId, balance);

        if (self.minLength == EMPTY) {
            self.minLength = 10;
        }

        uint sum = count(self) - 1;
        uint size = sum > 0 ? ((100 * (rank(self, balance) - 1)) / sum) : 100;

        uint8 length = uint8(((size - (size % 10)) / 10) + 1);
        if (length < self.minLength) {
            length = self.minLength - 1;
            self.minLength = length;
        }
        return length;
    }

    function insert(Tree storage self, uint16 key, uint value) public {
        if (!exists(self, value)) {
            require(value != EMPTY, "zero");
            uint cursor = EMPTY;
            uint probe = self.root;
            while (probe != EMPTY) {
                cursor = probe;
                if (value < probe) {
                    probe = self.nodes[probe].left;
                } else if (value > probe) {
                    probe = self.nodes[probe].right;
                } else if (value == probe) {
                    self.nodes[probe].keys.push(key);
                    return;
                }
                self.nodes[cursor].count++;
            }
            Node storage nValue = self.nodes[value];
            nValue.parent = cursor;
            nValue.left = EMPTY;
            nValue.right = EMPTY;
            nValue.red = true;
            nValue.keys.push(key);
            if (cursor == EMPTY) {
                self.root = value;
            } else if (value < cursor) {
                self.nodes[cursor].left = value;
            } else {
                self.nodes[cursor].right = value;
            }
            insertFixup(self, value);
        }
    }

    function rotateLeft(Tree storage self, uint value) private {
        uint cursor = self.nodes[value].right;
        uint parent = self.nodes[value].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[value].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = value;
        }
        self.nodes[cursor].parent = parent;
        if (parent == EMPTY) {
            self.root = cursor;
        } else if (value == self.nodes[parent].left) {
            self.nodes[parent].left = cursor;
        } else {
            self.nodes[parent].right = cursor;
        }
        self.nodes[cursor].left = value;
        self.nodes[value].parent = cursor;
        self.nodes[value].count = getNodeCount(self, self.nodes[value].left) + getNodeCount(self, self.nodes[value].right);
        self.nodes[cursor].count = getNodeCount(self, self.nodes[cursor].left) + getNodeCount(self, self.nodes[cursor].right);
    }

    function rotateRight(Tree storage self, uint value) private {
        uint cursor = self.nodes[value].left;
        uint parent = self.nodes[value].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[value].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = value;
        }
        self.nodes[cursor].parent = parent;
        if (parent == EMPTY) {
            self.root = cursor;
        } else if (value == self.nodes[parent].right) {
            self.nodes[parent].right = cursor;
        } else {
            self.nodes[parent].left = cursor;
        }
        self.nodes[cursor].right = value;
        self.nodes[value].parent = cursor;
        self.nodes[value].count = getNodeCount(self, self.nodes[value].left) + getNodeCount(self, self.nodes[value].right);
        self.nodes[cursor].count = getNodeCount(self, self.nodes[cursor].left) + getNodeCount(self, self.nodes[cursor].right);
    }

    function insertFixup(Tree storage self, uint value) private {
        uint cursor;
        while (value != self.root && self.nodes[self.nodes[value].parent].red) {
            uint valueParent = self.nodes[value].parent;
            if (valueParent == self.nodes[self.nodes[valueParent].parent].left) {
                cursor = self.nodes[self.nodes[valueParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[valueParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    value = self.nodes[valueParent].parent;
                } else {
                    if (value == self.nodes[valueParent].right) {
                        value = valueParent;
                        rotateLeft(self, value);
                    }
                    valueParent = self.nodes[value].parent;
                    self.nodes[valueParent].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    rotateRight(self, self.nodes[valueParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[valueParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[valueParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    value = self.nodes[valueParent].parent;
                } else {
                    if (value == self.nodes[valueParent].left) {
                        value = valueParent;
                        rotateRight(self, value);
                    }
                    valueParent = self.nodes[value].parent;
                    self.nodes[valueParent].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    rotateLeft(self, self.nodes[valueParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }
}
