// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IERC20Burnable is IERC20 {
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}