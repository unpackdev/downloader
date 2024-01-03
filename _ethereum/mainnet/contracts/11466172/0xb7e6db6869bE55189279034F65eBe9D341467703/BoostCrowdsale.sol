// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./WhitelistAdminRole.sol";
import "./WithrawableCrowdsale.sol";
import "./ReferralsCrowdsale.sol";
import "./IndividualCrowdsale.sol";
import "./RoundsCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";
import "./MinMaxCrowdsale.sol";
import "./WhitelistCrowdsale.sol";
import "./TimedCrowdsale.sol";

/**
 *     ____  ____  ____  ___________
 *    / __ )/ __ \/ __ \/ ___/_  __/
 *   / __  / / / / / / /\__ \ / /
 *  / /_/ / /_/ / /_/ /___/ // /
 * /_____/\____/\____//____//_/
 */
contract BoostCrowdsale is
Ownable,
Crowdsale,
WhitelistAdminRole,
TimedCrowdsale,
WhitelistCrowdsale,
WithrawableCrowdsale,
MinMaxCrowdsale,
PostDeliveryCrowdsale,
RoundsCrowdsale,
ReferralsCrowdsale,
IndividualCrowdsale
{
    using SafeMath for uint256;

    uint constant ROUNDS = 2;
    uint256 constant ROUND_CAP = 300000 ether;
    uint256 constant INIT_RATE = 650;
    uint256 constant RATE_DECREMENT = 150;

    constructor(
        IERC20 token,
        uint256 openingTime,
        uint256 closingTime,
        address whitelister
    )
    Crowdsale(INIT_RATE, msg.sender, token)
    WhitelistCrowdsale(whitelister)
    RoundsCrowdsale(ROUNDS, ROUND_CAP, INIT_RATE, RATE_DECREMENT)
    TimedCrowdsale(openingTime, closingTime)
    public {}
}
