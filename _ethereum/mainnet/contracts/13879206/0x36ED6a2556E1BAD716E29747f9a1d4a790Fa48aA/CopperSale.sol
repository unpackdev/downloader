pragma solidity ^0.5.5;

///////////////////////////////////////////////
/////////////// Token Crowdsale ///////////////
///////////////////////////////////////////////
//
// This is a Timed Crowdsale
//
// ============================================
// Properties are set by the Deployer Contract
// ============================================
//

import "./CopperToken.sol";
import "./Crowdsale.sol";
import "./MintedCrowdsale.sol";
import "./TimedCrowdsale.sol";


// RefundablePostDeliveryCrowdsale
contract CopperSale is Crowdsale, MintedCrowdsale, TimedCrowdsale {
    constructor(
        uint rate,
        address payable wallet,
        IERC20 token,
        uint256 openingTime,
        uint256 closingTime
    ) public  Crowdsale(rate, wallet, token)
        MintedCrowdsale()
        TimedCrowdsale(openingTime, closingTime) {}
}