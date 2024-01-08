// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./CancelableDelegatingVester.sol";


contract VestingFactory {
  address public immutable ndx;

  constructor(address ndx_) public {
    ndx = ndx_;
  }

  function createVestingContract(
    address terminator,
    address recipient,
    uint256 vestingAmount,
    uint256 numDays
  ) external {
    require(numDays <= 730, "Excessive duration");
    uint256 vestingBegin = block.timestamp;
    uint256 vestingEnd = vestingBegin + (numDays * 86400);
    CancelableDelegatingVester vester = new CancelableDelegatingVester(
      terminator,
      ndx,
      recipient,
      vestingAmount,
      vestingBegin,
      vestingEnd
    );
    INdx(ndx).transferFrom(msg.sender, address(vester), vestingAmount);
  }
}