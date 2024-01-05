// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./StringLib.sol";
import "./IMemeLtd.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./PowerLib.sol";

library BadgerScarcityPoolLib {
  using StringLib for *;
  uint256 constant FIXED_1 = 0x080000000000000000000000000000000;
  using SafeMath for *;
  struct PoolToken {
    uint256 tokenId;
    uint256 root;
  }
  struct Isolate {
    ERC20 bdigg;
    IMemeLtd memeLtd;
    BadgerScarcityPoolLib.PoolToken[] poolTokens;
    uint256 totalSupply;
  }
  function reserve(Isolate storage isolate) internal view returns (uint256 balance) {
    balance = isolate.bdigg.balanceOf(address(this));
  }
  function getPoolTokenRecord(Isolate storage isolate, uint256 tokenId) internal view returns (PoolToken storage) {
    for (uint256 i = 0; i < isolate.poolTokens.length; i++) {
      if (isolate.poolTokens[i].tokenId == tokenId) return isolate.poolTokens[i];
    }
    revert(abi.encodePacked("tokenId not found: ", bytes32(tokenId).toString()).toString());
  }
  function computeTotalNftsInContract(Isolate storage isolate, PoolToken storage poolToken) internal view returns (uint256 result) {
    result = isolate.memeLtd.balanceOf(address(this), poolToken.tokenId);
  }
  function computeTotalOutstanding(Isolate storage isolate, uint256 alreadyTransferred) internal view returns (uint256 result) {
    for (uint256 i = 0; i < isolate.poolTokens.length; i++) {
      result = result.add(computeTotalNftsInContract(isolate, isolate.poolTokens[i]));
    }
    result = isolate.totalSupply.sub(result).add(alreadyTransferred); //alreadyTransferred);
  }
  function sum(uint256[] memory values) internal pure returns (uint256 total) {
    for (uint256 i = 0; i < values.length; i++) {
      total = total.add(values[i]);
    }
  }
  function power(uint256 b, uint256 exp) internal pure returns (uint256 result) {
    (uint256 mantissa, uint8 exponent) = PowerLib.power(b, 1, uint8(exp/uint256(100)), uint8(uint256(100)));
    return mantissa >> exponent;
  }
  function computePayoutForToken(Isolate storage isolate, PoolToken storage poolToken, uint256 amount, uint256 alreadyTransferred, uint256 _reserve) internal view returns (uint256) {
    {
      return _reserve.mul(power(amount.mul(uint256(1e6)).div(computeTotalOutstanding(isolate, alreadyTransferred)), poolToken.root)).div(power(uint256(1e6), poolToken.root));
    }
  }
}
