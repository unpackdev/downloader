// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;
import "./IERC20.sol";

contract Refund {
  address holder;
  constructor(address _holder) {
    holder = _holder;
  }

  function refund(address token, uint256 amount) external {
    IERC20(token).transfer(holder, amount);
  }
}
