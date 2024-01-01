// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeGnosis {
  function relayTokens(address _receiver, uint256 _amount) external;
  function relayTokens(address _receiver) external payable;
  function totalBurntCoins() external view returns (uint256);
}
