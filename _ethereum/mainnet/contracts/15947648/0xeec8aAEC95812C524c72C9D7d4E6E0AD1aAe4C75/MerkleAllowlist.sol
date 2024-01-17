//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./MerkleProof.sol";
import "./Ownable.sol";

contract MerkleAllowlist is Ownable {
  bytes32 public publicAllowlistMerkleRoot;

  //Frontend verify functions
  function verifyPublicSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, _hash(userAddress), publicAllowlistMerkleRoot);
  }

  //Internal verify functions
  function _verifyPublicSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), publicAllowlistMerkleRoot);
  }

  function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 allowlistMerkleRoot)
    internal
    pure
    returns (bool)
  {
    return MerkleProof.verify(proof, allowlistMerkleRoot, addressHash);
  }

  function _hash(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }

  /*
  OWNER FUNCTIONS
  */

  function setPublicAllowlistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    publicAllowlistMerkleRoot = merkleRoot;
  }

  /*
  MODIFIER
  */
  
  modifier onlyPublicAllowlist(bytes32[] memory proof) {
    require(_verifyPublicSender(proof), "MerkleAllowlist: Caller is not allowlisted");
    _;
  }
}
