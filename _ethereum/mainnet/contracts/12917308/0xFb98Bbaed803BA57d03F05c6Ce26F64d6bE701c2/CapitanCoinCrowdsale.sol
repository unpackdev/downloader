// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./Crowdsale.sol";

contract CapitanCoinCrowdsale is Crowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token
    ) public Crowdsale(rate, wallet, token) {}
}
