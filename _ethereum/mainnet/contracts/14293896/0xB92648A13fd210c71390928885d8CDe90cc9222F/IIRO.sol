// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IIRO {
    enum Status {
        FUNDING, // Listing is being funded
        FAILED, // Goal not reached, contributors can pull funds
        AWAITING_TOKENS, // Awaiting tokens for distribution
        DISTRIBUTION // Success, contributors can pull tokens, owner can pull funds
    }

    function status() external view returns (IIRO.Status s);

    function enableDistribution(IERC20Upgradeable _listingToken) external;
}
