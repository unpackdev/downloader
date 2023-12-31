//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

library Encoder {
    function encodeNode(
        bytes32 node,
        bytes32 labelHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelHash));
    }
}
