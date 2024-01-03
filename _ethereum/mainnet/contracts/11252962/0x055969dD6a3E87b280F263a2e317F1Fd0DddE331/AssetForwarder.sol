pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./TokenUtils.sol";

contract AssetForwarder {
  using TokenUtils for *;
  bool public locked;
  function lock() public {
    locked = true;
  }
  function forwardAsset(address payable target, address token) public payable {
    require(!locked);
    if (token != address(0x0)) require(token.sendToken(target, IERC20(token).balanceOf(address(this))), "erc20 forward failure");
    selfdestruct(target);
  }
}
