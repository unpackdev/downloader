 
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiMerkleStash {
    struct claimParam {
      address token;
      uint256 index;
      uint256 amount;
      bytes32[] merkleProof;
  }
 
 function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
 function claimMulti(address account, claimParam[] calldata claims) external;
}