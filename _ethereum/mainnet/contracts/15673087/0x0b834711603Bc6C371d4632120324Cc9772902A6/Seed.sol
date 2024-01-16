// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Seed is Ownable {
  uint256 public seed;

  function update(uint256 _seed) external onlyOwner returns (uint256) {
    seed =
      seed ^
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            _seed,
            block.timestamp,
            blockhash(block.number - 1)
          )
        )
      );

    return seed;
  }
}
