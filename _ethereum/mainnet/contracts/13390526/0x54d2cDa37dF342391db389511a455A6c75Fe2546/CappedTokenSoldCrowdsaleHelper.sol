// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./SafeMath.sol";

/**
 * @title CappedTokenSoldCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale with a limit for total tokens sold.
 */
contract CappedTokenSoldCrowdsaleHelper {
    using SafeMath for uint256;

    uint256 private _tokenCap;

    /**
     * @param tokenCap_ Max amount of tokens to be sold
     */
    constructor(uint256 tokenCap_) {
        require(tokenCap_ > 0, "CappedTokenSoldHelper: zero cap");
        _tokenCap = tokenCap_;
    }

    modifier tokenCapNotExceeded(uint256 tokensSold, uint256 tokenAmount) {
        require(
            tokensSold.add(tokenAmount) <= _tokenCap,
            "CappedTokenSoldHelper: cap exceeded"
        );
        _;
    }

    /**
     * @return tokenCap_ the token cap of the crowdsale.
     */
    function tokenCap() public view returns (uint256 tokenCap_) {
        tokenCap_ = _tokenCap;
    }

    /**
     * @dev Checks whether the token cap has been reached.
     * @return tokenCapReached_ Whether the token cap was reached
     */
    function tokenCapReached(uint256 tokensSold)
        external
        view
        returns (bool tokenCapReached_)
    {
        tokenCapReached_ = (tokensSold >= _tokenCap);
    }
}
