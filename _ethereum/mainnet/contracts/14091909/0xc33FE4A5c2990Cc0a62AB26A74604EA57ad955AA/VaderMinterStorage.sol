// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later
pragma solidity =0.8.9;

import "./ILiquidityBasedTWAP.sol";

struct Limits {
    uint256 fee;
    uint256 mintLimit;
    uint256 burnLimit;
    uint256 lockDuration;
}

contract VaderMinterStorage {
    // The LBT pricing mechanism for the conversion
    ILiquidityBasedTWAP public lbt;

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    Limits public dailyLimits;

    // The current cycle end timestamp
    uint256 public cycleTimestamp;

    // The current cycle cumulative mints
    uint256 public cycleMints;

    // The current cycle cumulative burns
    uint256 public cycleBurns;

    // The limits applied to each partner
    mapping(address => Limits) public partnerLimits;

    // Transmuter Contract
    address public transmuter;
}
