// SPDX-License-Identifier: MIT
// Copyright 2023 SolidifyLabs
pragma solidity ^0.8.15;

import "./MintPassRedeemer.sol";
import "./ISellable.sol";

import "./Grails5.sol";
import "./Grails5MintPass.sol";

/**
 * @title Grails V: Mint Pass Redeemer
 * @notice The mint pass redeemer for phase 2
 */
contract Grails5MintPassRedeemer is FixedPricedMintPassForProjectIDRedeemer {
    constructor(Grails5 sellable_, Grails5MintPass pass_, uint256 price)
        FixedPricedMintPassForProjectIDRedeemer(sellable_, pass_, price)
    {}
}
