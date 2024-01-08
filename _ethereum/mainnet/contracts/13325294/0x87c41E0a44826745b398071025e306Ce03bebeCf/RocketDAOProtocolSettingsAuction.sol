/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAOProtocolSettings.sol";
import "./RocketDAOProtocolSettingsAuctionInterface.sol";

// Network auction settings

contract RocketDAOProtocolSettingsAuction is RocketDAOProtocolSettings, RocketDAOProtocolSettingsAuctionInterface {

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "auction") {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingBool("auction.lot.create.enabled", true);      
            setSettingBool("auction.lot.bidding.enabled", true);
            setSettingUint("auction.lot.value.minimum", 1 ether);   
            setSettingUint("auction.lot.value.maximum", 10 ether);
            setSettingUint("auction.lot.duration", 40320);          // 7 days
            setSettingUint("auction.price.start", 1 ether);         // 100%
            setSettingUint("auction.price.reserve", 0.5 ether);     // 50%
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }


    // Lot creation currently enabled
    function getCreateLotEnabled() override external view returns (bool) {
        return getSettingBool("auction.lot.create.enabled");
    }

    // Bidding on lots currently enabled
    function getBidOnLotEnabled() override external view returns (bool) {
        return getSettingBool("auction.lot.bidding.enabled");
    }

    // The minimum lot size relative to ETH value
    function getLotMinimumEthValue() override external view returns (uint256) {
        return getSettingUint("auction.lot.value.minimum");
    }

    // The maximum lot size relative to ETH value
    function getLotMaximumEthValue() override external view returns (uint256) {
        return getSettingUint("auction.lot.value.maximum");
    }

    // The maximum auction duration in blocks
    function getLotDuration() override external view returns (uint256) {
        return getSettingUint("auction.lot.duration");
    }

    // The starting price relative to current RPL price, as a fraction of 1 ether
    function getStartingPriceRatio() override external view returns (uint256) {
        return getSettingUint("auction.price.start");
    }

    // The reserve price relative to current RPL price, as a fraction of 1 ether
    function getReservePriceRatio() override external view returns (uint256) {
        return getSettingUint("auction.price.reserve");
    }

}
