//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ╔═╗─╔╦═══╦════╗╔════╦═══╦═╗╔═╗╔═══╦═══╦═══╦══╦═══╦═══╗
// ║║╚╗║║╔══╣╔╗╔╗║║╔╗╔╗║╔═╗╠╗╚╝╔╝║╔═╗║╔══╣╔══╩╣╠╣╔═╗║╔══╝
// ║╔╗╚╝║╚══╬╝║║╚╝╚╝║║╚╣║─║║╚╗╔╝─║║─║║╚══╣╚══╗║║║║─╚╣╚══╗
// ║║╚╗║║╔══╝─║║────║║─║╚═╝║╔╝╚╗─║║─║║╔══╣╔══╝║║║║─╔╣╔══╝
// ║║─║║║║────║║────║║─║╔═╗╠╝╔╗╚╗║╚═╝║║──║║──╔╣╠╣╚═╝║╚══╗
// ╚╝─╚═╩╝────╚╝────╚╝─╚╝─╚╩═╝╚═╝╚═══╩╝──╚╝──╚══╩═══╩═══╝
// Not Financial Advice: The avoidance of taxes is the only intellectual pursuit that still carries any reward. - John Maynard Keynes
// NFT Tax Office is not a real tax office.

import "./Yield.sol";

contract NFTTaxReturns is Yield {
    constructor(
        address targetAddress,
        address rewardAddress,
        uint256 baseRate,
        uint256 rewardFrequency,
        uint256 initialReward,
        uint256 stakeMultiplier
    )
        Yield(
            targetAddress,
            rewardAddress,
            baseRate,
            rewardFrequency,
            initialReward,
            stakeMultiplier
        )
    {}
}