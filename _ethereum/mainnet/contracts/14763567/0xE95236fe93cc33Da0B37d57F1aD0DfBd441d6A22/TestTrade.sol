// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./TradeV4.sol";

/// @title TestTrade
///
/// @dev This contract extends from Trade Series for upgradeablity testing

contract TestTrade is TradeV4 {
    uint256 public aNewValue;

    /// @notice trivial getter override, to verify actual change
    function sellerServiceFee() external view virtual override returns (uint8) {
        return 42;
    }
}
