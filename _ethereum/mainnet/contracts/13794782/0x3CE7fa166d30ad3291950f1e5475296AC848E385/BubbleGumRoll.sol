// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract BubbleGumRoll {
  function _rnd(string memory _k, uint256 _v) internal view returns (uint256) {
    return uint256(keccak256(abi.encode(tx.origin, blockhash(block.number-1), block.timestamp, _k, _v)));
  }

  function _roll(string memory _k, uint _id, uint _proba) internal view returns (bool) {
    return _rnd(_k, _id) % _proba == 0;
  }
}