// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Transfer {
  function transferFrom(address from, address to, uint256 tokenId) external;
}
