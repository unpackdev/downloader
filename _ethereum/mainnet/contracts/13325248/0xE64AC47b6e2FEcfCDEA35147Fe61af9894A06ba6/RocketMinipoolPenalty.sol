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

import "./SafeMath.sol";

import "./RocketBase.sol";
import "./RocketMinipoolPenaltyInterface.sol";

// Non-upgradable contract which gives guardian control over maximum penalty rates

contract RocketMinipoolPenalty is RocketBase, RocketMinipoolPenaltyInterface {

    // Events
    event MaxPenaltyRateUpdated(uint256 rate, uint256 time);

    // Libs
    using SafeMath for uint;

    // Storage (purposefully does not use RocketStorage to prevent oDAO from having power over this feature)
    uint256 maxPenaltyRate = 0 ether;                     // The most the oDAO is allowed to penalty a minipool (as a percentage)

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
    }

    // Get/set the current max penalty rate
    function setMaxPenaltyRate(uint256 _rate) external override onlyGuardian {
        // Update rate
        maxPenaltyRate = _rate;
        // Emit event
        emit MaxPenaltyRateUpdated(_rate, block.timestamp);
    }
    function getMaxPenaltyRate() external override view returns (uint256) {
        return maxPenaltyRate;
    }

    // Retrieves the amount to penalty a minipool
    function getPenaltyRate(address _minipoolAddress) external override view returns(uint256) {
        // Quick out which avoids a call to RocketStorage
        if (maxPenaltyRate == 0) {
             return 0;
        }
        // Retrieve penalty rate for this minipool
        uint256 penaltyRate = getUint(keccak256(abi.encodePacked("minipool.penalty.rate", _minipoolAddress)));
        // min(maxPenaltyRate, penaltyRate)
        if (penaltyRate > maxPenaltyRate) {
            return maxPenaltyRate;
        }
        return penaltyRate;
    }

    // Sets the penalty rate for the given minipool
    function setPenaltyRate(address _minipoolAddress, uint256 _rate) external override onlyLatestNetworkContract {
        setUint(keccak256(abi.encodePacked("minipool.penalty.rate", _minipoolAddress)), _rate);
    }
}
