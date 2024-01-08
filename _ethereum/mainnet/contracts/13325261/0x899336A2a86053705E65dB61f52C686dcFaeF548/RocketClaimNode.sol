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
import "./RocketNodeManagerInterface.sol";
import "./RocketNodeStakingInterface.sol";
import "./RocketRewardsPoolInterface.sol";
import "./RocketClaimNodeInterface.sol";

// RPL Rewards claiming for regular nodes

contract RocketClaimNode is RocketBase, RocketClaimNodeInterface {

    // Libs
    using SafeMath for uint;

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Get whether the contract is enabled for claims
    function getEnabled() override external view returns (bool) {
        RocketRewardsPoolInterface rocketRewardsPool = RocketRewardsPoolInterface(getContractAddress("rocketRewardsPool"));
        return rocketRewardsPool.getClaimingContractEnabled("rocketClaimNode");
    }

    // Get whether a node can make a claim
    function getClaimPossible(address _nodeAddress) override public view onlyRegisteredNode(_nodeAddress) returns (bool) {
        // Load contracts
        RocketRewardsPoolInterface rocketRewardsPool = RocketRewardsPoolInterface(getContractAddress("rocketRewardsPool"));
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        // Return claim possible status
        return (
            rocketRewardsPool.getClaimingContractUserCanClaim("rocketClaimNode", _nodeAddress) &&
            rocketNodeStaking.getNodeRPLStake(_nodeAddress) >= rocketNodeStaking.getNodeMinimumRPLStake(_nodeAddress)
        );
    }

    // Get the share of rewards for a node as a fraction of 1 ether
    function getClaimRewardsPerc(address _nodeAddress) override public view onlyRegisteredNode(_nodeAddress) returns (uint256) {
        // Check node can claim
        if (!getClaimPossible(_nodeAddress)) { return 0; }
        // Load contracts
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        // Calculate and return share
        uint256 totalRplStake = rocketNodeStaking.getTotalEffectiveRPLStake();
        if (totalRplStake == 0) { return 0; }
        return calcBase.mul(rocketNodeStaking.getNodeEffectiveRPLStake(_nodeAddress)).div(totalRplStake);
    }

    // Get the amount of rewards for a node for the reward period
    function getClaimRewardsAmount(address _nodeAddress) override external view onlyRegisteredNode(_nodeAddress) returns (uint256) {
        RocketRewardsPoolInterface rocketRewardsPool = RocketRewardsPoolInterface(getContractAddress("rocketRewardsPool"));
        return rocketRewardsPool.getClaimAmount("rocketClaimNode", _nodeAddress, getClaimRewardsPerc(_nodeAddress));
    }

    // Register or deregister a node for RPL claims
    // Only accepts calls from the RocketNodeManager contract
    function register(address _nodeAddress, bool _enable) override external onlyLatestContract("rocketClaimNode", address(this)) onlyLatestContract("rocketNodeManager", msg.sender) onlyRegisteredNode(_nodeAddress) {
        RocketRewardsPoolInterface rocketRewardsPool = RocketRewardsPoolInterface(getContractAddress("rocketRewardsPool"));
        rocketRewardsPool.registerClaimer(_nodeAddress, _enable);
    }

    // Make an RPL claim
    // Only accepts calls from registered nodes
    function claim() override external onlyLatestContract("rocketClaimNode", address(this)) onlyRegisteredNode(msg.sender) {
        // Check that the node can claim
        require(getClaimPossible(msg.sender), "The node is currently unable to claim");
        // Get node withdrawal address
        RocketNodeManagerInterface rocketNodeManager = RocketNodeManagerInterface(getContractAddress("rocketNodeManager"));
        address nodeWithdrawalAddress = rocketNodeManager.getNodeWithdrawalAddress(msg.sender);
        // Claim RPL
        RocketRewardsPoolInterface rocketRewardsPool = RocketRewardsPoolInterface(getContractAddress("rocketRewardsPool"));
        rocketRewardsPool.claim(msg.sender, nodeWithdrawalAddress, getClaimRewardsPerc(msg.sender));
    }

}
