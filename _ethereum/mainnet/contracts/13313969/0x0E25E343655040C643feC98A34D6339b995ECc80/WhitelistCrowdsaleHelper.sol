// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./IWhitelist.sol";

/**
 * @title WhitelistCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistCrowdsaleHelper {
    address public whitelistContract;

    /**
     * @param whitelistContract_ whitelist contract address
     */
    constructor(address whitelistContract_) {
        require(
            whitelistContract_ != address(0),
            "WhitelistCrowdsaleHelper: zero whitelist address"
        );

        whitelistContract = whitelistContract_;
    }

    modifier isWhitelisted(address account) {
        require(
            IWhitelist(whitelistContract).isWhitelisted(account),
            "WhitelistCrowdsaleHelper: account not whitelisted"
        );
        _;
    }

    function whitelisted(address account)
        public
        view
        returns (bool whitelisted_)
    {
        whitelisted_ = IWhitelist(whitelistContract).isWhitelisted(account);
    }
}
