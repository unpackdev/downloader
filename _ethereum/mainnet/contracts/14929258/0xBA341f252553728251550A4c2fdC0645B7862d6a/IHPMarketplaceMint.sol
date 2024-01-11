// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IHPMarketplaceMint {
  function marketplaceMint(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) external returns(uint256);

  function canMarketplaceMint() external pure returns(bool);
}