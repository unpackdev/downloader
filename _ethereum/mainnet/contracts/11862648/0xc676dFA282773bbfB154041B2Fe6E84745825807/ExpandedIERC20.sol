// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./IERC20.sol";

abstract contract ExpandedIERC20 is IERC20 {
  function burn(uint256 value) external virtual;

  function mint(address to, uint256 value) external virtual returns (bool);

  function addMinter(address account) external virtual;

  function addBurner(address account) external virtual;

  function resetOwner(address account) external virtual;
}
