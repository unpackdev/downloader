// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20.sol";

interface IERC20UtilityToken is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}
