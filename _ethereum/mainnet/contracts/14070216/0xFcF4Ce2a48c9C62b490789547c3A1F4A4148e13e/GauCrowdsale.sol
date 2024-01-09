//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableCrowdsale.sol";
import "./DisabableCrowdsale.sol";

contract GauCrowdsale is DisabableCrowdsale {

    constructor( uint256 __ethRate, address payable wallet, IERC20 gauf)
    DisabableCrowdsale( __ethRate, wallet, gauf)
    {}

}