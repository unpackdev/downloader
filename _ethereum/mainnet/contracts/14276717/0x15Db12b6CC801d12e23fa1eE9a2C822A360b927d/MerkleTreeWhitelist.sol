// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "./MerkleProof.sol";

import "./AbstractWhitelist.sol";

contract MerkleTreeWhitelist is AbstractWhitelist {
  mapping(address => bool) public whitelistClaimed;

  bytes32 public merkleRoot;

  constructor(bytes32 merkleRoot_) {
    merkleRoot = merkleRoot_;
  }

  function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    merkleRoot = merkleRoot_;
  }

  modifier isWhitelisted(bytes32[] calldata merkleProof_) {
    require(isWhitelistSale, "not whitelist sale");
    require(!whitelistClaimed[msg.sender], "whitelist claimed");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof_, merkleRoot, leaf), "invalid proof");

    // perform mint
    _;

    whitelistClaimed[msg.sender] = true;
  }
}
