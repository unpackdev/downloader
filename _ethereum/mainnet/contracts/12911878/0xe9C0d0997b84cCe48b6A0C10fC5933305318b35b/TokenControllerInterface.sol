// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

interface TokenControllerInterface {
  function beforeTokenTransfer(address from, address to, uint256 amount) external;
}
