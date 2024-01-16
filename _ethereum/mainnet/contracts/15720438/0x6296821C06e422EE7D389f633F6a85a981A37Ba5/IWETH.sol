// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
  function withdraw(uint256) external;
}
