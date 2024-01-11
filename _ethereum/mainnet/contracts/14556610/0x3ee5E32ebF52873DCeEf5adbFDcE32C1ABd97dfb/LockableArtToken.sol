//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LockableArtToken {
   function isArtTokenLocked(uint256 artTokenId) external view returns (bool);
   function lockArtToken(uint256 artTokenId) external; 
}