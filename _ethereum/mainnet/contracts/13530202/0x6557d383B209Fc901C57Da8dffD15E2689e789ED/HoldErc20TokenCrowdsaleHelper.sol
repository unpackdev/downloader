// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./SafeERC20.sol";

/**
 * @title HoldErc20TokenCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale where only wallets with specified amount of ERC20 token can contribute.
 */
contract HoldErc20TokenCrowdsaleHelper {
    using SafeERC20 for IERC20;

    address public tokenHoldContract;
    uint256 public minTokenHoldAmount;

    /**
     * @param tokenHoldContract_ ERC20 token contract address
     * @param minTokenHoldAmount_ minimum amount of token required to hold
     */
    constructor(address tokenHoldContract_, uint256 minTokenHoldAmount_) {
        require(
            tokenHoldContract_ != address(0),
            "HoldErc20TokenCrowdsaleHelper: zero token hold address"
        );

        require(
            minTokenHoldAmount_ > 0,
            "HoldErc20TokenCrowdsaleHelper: zero min token hold amount"
        );

        tokenHoldContract = tokenHoldContract_;
        minTokenHoldAmount = minTokenHoldAmount_;
    }

    modifier holdsSufficientTokens(address account) {
        require(
            IERC20(tokenHoldContract).balanceOf(account) >= minTokenHoldAmount,
            "HoldErc20TokenCrowdsaleHelper: account hold less than min"
        );
        _;
    }
}
