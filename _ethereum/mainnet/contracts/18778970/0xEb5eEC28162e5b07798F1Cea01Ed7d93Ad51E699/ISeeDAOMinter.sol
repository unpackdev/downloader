// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ISeeDAOMinter {
  error InsufficientERC20Balance();
  error InsufficientERC721Balance();
  error InsufficientERC1155Balance();

  error InsufficientPayment();
  error InsufficientAllowance();

  event WhitelistAdd(uint256 whitelistId, bytes32 rootHash);
}
