// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ILostSocksGenesis {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function isLeft(uint256 tokenId) external view returns (bool);
}
