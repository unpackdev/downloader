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
import "./SafeCast.sol";

import "./RocketBase.sol";
import "./RocketDepositPoolInterface.sol";
import "./RocketMinipoolQueueInterface.sol";
import "./RocketNetworkFeesInterface.sol";
import "./RocketDAOProtocolSettingsNetworkInterface.sol";

// Network node demand and commission rate

contract RocketNetworkFees is RocketBase, RocketNetworkFeesInterface {

    // Libs
    using SafeMath for uint;
    using SafeCast for uint;

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Get the current RP network node demand in ETH
    // Node demand is equal to deposit pool balance minus available minipool capacity
    function getNodeDemand() override public view returns (int256) {
        // Load contracts
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        // Calculate & return
        int256 depositPoolBalance = rocketDepositPool.getBalance().toInt256();
        int256 minipoolCapacity = rocketMinipoolQueue.getEffectiveCapacity().toInt256();
        int256 demand = depositPoolBalance - minipoolCapacity;
        require(demand <= depositPoolBalance);
        return demand;
    }

    // Get the current RP network node fee as a fraction of 1 ETH
    function getNodeFee() override external view returns (uint256) {
        return getNodeFeeByDemand(getNodeDemand());
    }

    // Get the RP network node fee for a node demand value
    function getNodeFeeByDemand(int256 _nodeDemand) override public view returns (uint256) {
        // Calculation base values
        uint256 demandDivisor = 1000000000000;
        // Get settings
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        uint256 minFee = rocketDAOProtocolSettingsNetwork.getMinimumNodeFee();
        uint256 targetFee = rocketDAOProtocolSettingsNetwork.getTargetNodeFee();
        uint256 maxFee = rocketDAOProtocolSettingsNetwork.getMaximumNodeFee();
        uint256 demandRange = rocketDAOProtocolSettingsNetwork.getNodeFeeDemandRange();
        // Normalize node demand
        uint256 nNodeDemand;
        bool nNodeDemandSign;
        if (_nodeDemand < 0) {
            nNodeDemand = uint256(-_nodeDemand);
            nNodeDemandSign = false;
        } else {
            nNodeDemand = uint256(_nodeDemand);
            nNodeDemandSign = true;
        }
        nNodeDemand = nNodeDemand.mul(calcBase).div(demandRange);
        // Check range bounds
        if (nNodeDemand == 0) { return targetFee; }
        if (nNodeDemand >= calcBase) {
            if (nNodeDemandSign) { return maxFee; }
            return minFee;
        }
        // Get fee interpolation factor
        uint256 t = nNodeDemand.div(demandDivisor) ** 3;
        // Interpolate between min / target / max fee
        if (nNodeDemandSign) { return targetFee.add(maxFee.sub(targetFee).mul(t).div(calcBase)); }
        return minFee.add(targetFee.sub(minFee).mul(calcBase.sub(t)).div(calcBase));
    }

}
