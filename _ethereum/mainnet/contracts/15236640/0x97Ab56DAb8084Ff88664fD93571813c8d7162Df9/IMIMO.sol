// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";

interface IMIMO is IERC20 {
  function burn(address account, uint256 amount) external;

  function mint(address account, uint256 amount) external;
}
