// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IERC721Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IMerkleDistributor.sol";

contract MerkleClaim is IMerkleDistributor {
  mapping (address => bytes32) public override merkleRoot;
  mapping (address => mapping(bytes32 => bool)) internal claimedNodes;

  function _hasValidClaim(
    address contractAddress,
    bytes32 merkleNode,
    bytes32[] calldata merkleProof
  )
    internal
    view
    virtual
    returns(bool)
  {
    if (claimedNodes[contractAddress][merkleNode]) { return false; }
    return MerkleProofUpgradeable.verifyCalldata(merkleProof, merkleRoot[contractAddress], merkleNode);
  }

  function _setNodeClaimed(address contractAddress, bytes32 merkleNode) internal virtual {
    claimedNodes[contractAddress][merkleNode] = true;
  }

  function _setMerkleRoot(address contractAddress, bytes32 merkleRoot_) internal virtual {
    merkleRoot[contractAddress] = merkleRoot_;
  }
}
