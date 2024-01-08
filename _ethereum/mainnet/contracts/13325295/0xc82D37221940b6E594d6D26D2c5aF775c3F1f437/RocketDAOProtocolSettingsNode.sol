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
import "./RocketDAOProtocolSettingsNodeInterface.sol";

// Network auction settings

contract RocketDAOProtocolSettingsNode is RocketDAOProtocolSettings, RocketDAOProtocolSettingsNodeInterface {

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "node") {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingBool("node.registration.enabled", false);
            setSettingBool("node.deposit.enabled", false);
            setSettingUint("node.per.minipool.stake.minimum", 0.1 ether);      // 10% of user ETH value
            setSettingUint("node.per.minipool.stake.maximum", 1.5 ether);      // 150% of user ETH value
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    // Node registrations currently enabled
    function getRegistrationEnabled() override external view returns (bool) {
        return getSettingBool("node.registration.enabled");
    }

    // Node deposits currently enabled
    function getDepositEnabled() override external view returns (bool) {
        return getSettingBool("node.deposit.enabled");
    }

    // Minimum RPL stake per minipool as a fraction of assigned user ETH value
    function getMinimumPerMinipoolStake() override external view returns (uint256) {
        return getSettingUint("node.per.minipool.stake.minimum");
    }

    // Maximum RPL stake per minipool as a fraction of assigned user ETH value
    function getMaximumPerMinipoolStake() override external view returns (uint256) {
        return getSettingUint("node.per.minipool.stake.maximum");
    }

}
