// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWhitelistMerkle {
    function isValidProof(bytes32[] calldata proof, bytes32 leaf) external view returns (bool);
    function setNewRootHash(bytes32 _rootHash) external;
}
