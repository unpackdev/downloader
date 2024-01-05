// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./MerkleProof.sol";
import "./IMerkleTreeManager.sol";

contract MerkleTreeManager is IMerkleTreeManager {
    function proof(
        uint256 treeId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) virtual public returns(bool) {
        require(!isProven(treeId, index), 'MerkleTree: Already proven.');
        bytes32 merkleRoot = merkleRootMap[treeId];

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleTree: Invalid proof.');

        // Mark it claimed and send the token.
        _setProven(treeId, index);

        return true;
    }
}
