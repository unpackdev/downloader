// // SPDX-License-Identifier: MIT
/******************************************************************************\
* (https://github.com/shroomtopia)
* ShroomTopia's ERC20 SPOR Token Interface
/******************************************************************************/

pragma solidity ^0.8.3;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

interface ISPORToken is IERC20Metadata {
  function mint(address user, uint256 amount) external;
}
