// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./IERC165Upgradeable.sol";

interface TokenListenerInterface is IERC165Upgradeable {
  function beforeTokenMint(address to, uint256 amount, address controlledToken) external;
  function beforeTokenTransfer(address from, address to, uint256 amount, address controlledToken) external;
}