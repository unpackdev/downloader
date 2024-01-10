// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAuction_House_V1_0 {
  function togglePause(uint256 tokenId) external;
  function redeem(uint256 tokenId) external;
  function isPaused(uint256 tokenId) external view returns(bool);

  event Redeem(uint256 tokenId, address owner);
  event Pause(uint256 tokenId, bool isPaused);
}