// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./MintedCrowdsale.sol";
import "./CappedCrowdsale.sol";

contract CatsTokenR3 is Crowdsale, MintedCrowdsale, CappedCrowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 cap
    )
        MintedCrowdsale()
        CappedCrowdsale(cap)
        Crowdsale(rate, wallet, token)
        public
    {

    }
}
