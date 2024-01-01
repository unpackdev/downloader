// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Initializable.sol";
import "./MerkleProof.sol";

import "./IMerkleSet.sol";

/**
 * @title MerkleSet
 * @notice Checks merkle proofs
 * @dev Contracts inheriting from MerkleSet may update the merkle root whenever desired.
 */
contract MerkleSetInitializable is Initializable, IMerkleSet {
    bytes32 private merkleRoot;

    function __MerkleSet_init(bytes32 _merkleRoot) internal onlyInitializing {
        _setMerkleRoot(_merkleRoot);
    }

    modifier validMerkleProof(bytes32 leaf, bytes32[] memory merkleProof) {
        _verifyMembership(leaf, merkleProof);

        _;
    }

    /**
     * @notice Tests membership in the merkle set
     */
    function _testMembership(bytes32 leaf, bytes32[] memory merkleProof) internal view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    /**
     * @dev Verifies membership in the merkle set
     */
    function _verifyMembership(bytes32 leaf, bytes32[] memory merkleProof) internal view {
        require(_testMembership(leaf, merkleProof), "invalid proof");
    }

    /**
     * @dev Updates the merkle root
     */
    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
        emit SetMerkleRoot(merkleRoot);
    }
}
