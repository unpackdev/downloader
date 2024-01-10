// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "./IERC20.sol";

interface IUTD is IERC20 {
  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}
