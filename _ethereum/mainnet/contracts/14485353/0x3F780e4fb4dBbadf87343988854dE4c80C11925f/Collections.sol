//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library Collections {
    struct LinkedList {
        mapping(uint256 => uint256) nodeToValue;
        mapping(uint256 => uint256) nodeLinks;
    }

    function addNode(
        LinkedList storage self,
        uint256 id,
        uint256 value
    ) internal {
        self.nodeToValue[id] = value;
        if (self.nodeLinks[0] == 0) {
            self.nodeLinks[0] = id;
            return;
        }

        uint256 lastNodeId = 0;
        uint256 currentNodeId = self.nodeLinks[0];
        while (currentNodeId != 0) {
            uint256 currentNodeValue = self.nodeToValue[currentNodeId];
            if (value < currentNodeValue) {
                self.nodeLinks[lastNodeId] = id;
                self.nodeLinks[id] = currentNodeId;
                return;
            }
            uint256 nextNodeId = self.nodeLinks[currentNodeId];
            lastNodeId = currentNodeId;
            currentNodeId = nextNodeId;
        }

        self.nodeLinks[lastNodeId] = id;
    }

    function removeNode(LinkedList storage self, uint256 id) internal {
        uint256 lastNodeId = 0;
        uint256 currentNodeId = self.nodeLinks[0];
        while (currentNodeId != 0) {
            uint256 nextNodeId = self.nodeLinks[currentNodeId];
            if (currentNodeId == id) {
                self.nodeLinks[lastNodeId] = nextNodeId;
                delete self.nodeLinks[id];
                break;
            }
            currentNodeId = nextNodeId;
        }
    }
}
