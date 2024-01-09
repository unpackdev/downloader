// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Shareholder.sol";
import "./TokenDiscount.sol";

struct ArtistContractConfig {
    string name;
    string symbol;
    address[] withdrawAdmins;
    address[] stateAdmins;
    address[] mintForFree;
    uint256 initialPrice;
    uint256 supplyCap;
    uint256 maxBatchSize;
    Shareholder[] shareholders;
    TokenDiscountInput[] tokenDiscounts;
}
