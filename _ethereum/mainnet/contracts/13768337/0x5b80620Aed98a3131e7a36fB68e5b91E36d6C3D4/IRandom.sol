// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IRandom {
  function submitHash(address sender, uint256 tokenId) external;
  function getRandomNumber(uint256 tokenId) external returns (uint256);
}
