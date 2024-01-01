// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";


interface IProofFeedsCommons {

    struct SignedMerkleTreeRoot {
        uint32 epoch;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 root;
    }

    /// @dev must be keccak256("MerkleTreeRoot(uint32 epoch,bytes32 root)")
    function MERKLE_TREE_ROOT_TYPE_HASH() external view returns (bytes32);
}
