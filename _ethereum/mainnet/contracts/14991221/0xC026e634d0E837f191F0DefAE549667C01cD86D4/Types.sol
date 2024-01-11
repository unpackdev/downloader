// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

struct TierInfo {
  uint256 nextTokenId;
  uint256 minTokenId;
  uint256 totalSupply;
}

struct ReservePayload {
  address account;
  uint256 amount;
  uint256 tier;
}

struct SalesInfo {
  uint256 tier2WhitelistedAmount;
  uint256 tier3WhitelistedAmount;
  uint256 tier2RemainingAmount;
  uint256 tier3RemainingAmount;
  uint256 whitelistTier2Price;
  uint256 whitelistTier3Price;
  uint256 tier2Price;
  uint256 tier3Price;
  uint256 userCap;
  uint256 presaleStart;
  uint256 publicSaleStart;
  uint256 publicSaleEnd;
}
