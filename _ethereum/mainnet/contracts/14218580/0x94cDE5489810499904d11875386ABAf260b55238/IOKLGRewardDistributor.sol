// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOKLGRewardDistributor {
  function depositRewards(address tokenAddress, uint256 erc20DirectAmount)
    external
    payable;

  function getShares(address wallet) external view returns (uint256);

  function getBoostNfts(address wallet)
    external
    view
    returns (uint256[] memory);
}
