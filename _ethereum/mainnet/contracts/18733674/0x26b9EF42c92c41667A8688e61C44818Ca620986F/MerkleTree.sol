pragma solidity ^0.8.19;

import "./Math.sol";

library MerkleTree {
    function getRoot(bytes32[] memory data) internal pure returns (bytes32) {
        uint256 n = data.length;

        if (n == 1) {
            return data[0];
        }

        uint256 j = 0;
        uint256 layer = 0;
        uint256 leaves = Math.log2(n) + 1;
        bytes32[][] memory nodes = new bytes32[][](leaves * (2 * n - 1));

        for (uint256 i = 0; i <= leaves; ) {
            nodes[i] = new bytes32[](2 * n - 1);
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < data.length; ) {
            nodes[layer][j] = data[i];
            unchecked {
                ++j;
                ++i;
            }
        }

        while (n > 1) {
            uint256 layerNodes = 0;
            uint256 k = 0;

            for (uint256 i = 0; i < n; i += 2) {
                if (i + 1 == n) {
                    if (n % 2 == 1) {
                        nodes[layer + 1][k] = nodes[layer][n - 1];
                        unchecked {
                            ++j;
                            ++layerNodes;
                        }
                        continue;
                    }
                }

                nodes[layer + 1][k] = _hashPair(nodes[layer][i], nodes[layer][i + 1]);

                unchecked {
                    ++k;
                    layerNodes += 2;
                }
            }

            n = (n / 2) + (layerNodes % 2 == 0 ? 0 : 1);
            unchecked {
                ++layer;
            }
        }

        return nodes[layer][0];
    }

    function _efficientHash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }
}
