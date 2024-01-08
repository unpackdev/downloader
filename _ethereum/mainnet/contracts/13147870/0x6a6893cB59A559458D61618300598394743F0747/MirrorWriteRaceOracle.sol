// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IMirrorWriteRaceOracle.sol";
import "./Ownable.sol";

/**
 * @title MirrorWriteRaceOracle
 * @author MirrorXYZ
 */
contract MirrorWriteRaceOracle is IMirrorWriteRaceOracle, Ownable {
    /// @notice Merkle root
    bytes32 public root;

    constructor(address owner_, bytes32 root_) Ownable(owner_) {
        root = root_;
    }

    function updateRoot(bytes32 newRoot) public override onlyOwner {
        root = newRoot;
    }

    /**
     * @notice verifies that an account has participated in the Write Race.
     * see: https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
     */
    function verify(
        address account,
        uint256 index,
        bytes32[] memory proof
    ) public view override returns (bool) {
        bytes32 computedHash = getNode(account, index);

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function getNode(address account, uint256 index)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, index));
    }
}
