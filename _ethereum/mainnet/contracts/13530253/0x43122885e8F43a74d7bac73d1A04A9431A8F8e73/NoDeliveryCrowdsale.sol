// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./Crowdsale.sol";

/**
 * @title NoDeliveryCrowdsale
 * @author Enjinstarter
 * @dev Extension of Crowdsale contract where purchased tokens are not delivered.
 */
abstract contract NoDeliveryCrowdsale is Crowdsale {
    /**
     * @dev Overrides delivery by not delivering tokens upon purchase.
     */
    function _deliverTokens(address, uint256) internal pure override {
        return;
    }
}
