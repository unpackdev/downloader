// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library MarketLib {
  struct Redeemed {
        uint256 redeemedId;
        address redeemer;
        uint256 certId;
        uint256 amount;
    }
}