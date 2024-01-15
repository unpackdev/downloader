// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INftPriceOracle.sol";
import "./IFloorPricePredictionV2.sol";

abstract contract FloorPricePredictionStorageV1 is IFloorPricePredictionV2 {
    INftPriceOracle public oracle;
    address public adminAddress; // address of the admin
    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // accumulated treasury amount

    mapping(address => Market) public markets;
    address[] public nftsContracts;
    mapping(address => uint256) public _referralFunds; // per referrer
    mapping(address => address) public _referrers; // newUser => referrer

    uint256 public referralRewardRatio; //10 = 1%
    uint256 public houseBetBase; //0.005eth = 5*10**15
    uint256 public houseBetFund;
    uint256 public houseBetFundEndsAt;
}
