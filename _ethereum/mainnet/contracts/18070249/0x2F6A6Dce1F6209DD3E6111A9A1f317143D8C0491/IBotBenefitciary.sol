// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DABotCommon.sol"; 


/**
@dev The interface of a bot benefitciary who is awarded from the bot's activities.
 */
interface IBotBenefitciary {

    function name() external view returns(string memory);
    function shortName() external view returns(string memory);
    function onAward(uint amount) external;
}