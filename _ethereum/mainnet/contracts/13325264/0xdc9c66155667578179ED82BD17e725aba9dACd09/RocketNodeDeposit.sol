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
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
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
import "./RocketDepositPoolInterface.sol";
import "./RocketMinipoolInterface.sol";
import "./RocketMinipoolManagerInterface.sol";
import "./RocketNetworkFeesInterface.sol";
import "./RocketNodeDepositInterface.sol";
import "./RocketDAOProtocolSettingsDepositInterface.sol";
import "./RocketDAOProtocolSettingsMinipoolInterface.sol";
import "./RocketDAOProtocolSettingsNodeInterface.sol";
import "./RocketDAOProtocolSettingsNetworkInterface.sol";
import "./RocketDAONodeTrustedInterface.sol";
import "./RocketDAONodeTrustedSettingsMembersInterface.sol";
import "./MinipoolDeposit.sol";

// Handles node deposits and minipool creation

contract RocketNodeDeposit is RocketBase, RocketNodeDepositInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Accept a node deposit and create a new minipool under the node
    // Only accepts calls from registered nodes
    function deposit(uint256 _minimumNodeFee) override external payable onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Load contracts
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkFeesInterface rocketNetworkFees = RocketNetworkFeesInterface(getContractAddress("rocketNetworkFees"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getDepositEnabled(), "Node deposits are currently disabled");
        // Check current node fee
        uint256 nodeFee = rocketNetworkFees.getNodeFee();
        require(nodeFee >= _minimumNodeFee, "Minimum node fee exceeds current network node fee");
        // Get deposit type by node deposit amount
        MinipoolDeposit depositType = MinipoolDeposit.None;
        if (msg.value == rocketDAOProtocolSettingsMinipool.getFullDepositNodeAmount()) { depositType = MinipoolDeposit.Full; }
        else if (msg.value == rocketDAOProtocolSettingsMinipool.getHalfDepositNodeAmount()) { depositType = MinipoolDeposit.Half; }
        else if (msg.value == rocketDAOProtocolSettingsMinipool.getEmptyDepositNodeAmount()) { depositType = MinipoolDeposit.Empty; }
        else {
            // Invalid deposit amount
            revert("Invalid node deposit amount");
        }
        // If creating an unbonded minipool, check current unbonded minipool count and current fee > 80% of max
        if (depositType == MinipoolDeposit.Empty) {
            RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
            RocketDAONodeTrustedInterface rocketDaoNodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
            RocketDAONodeTrustedSettingsMembersInterface rocketDaoNodeTrustedSettingsMembers = RocketDAONodeTrustedSettingsMembersInterface(getContractAddress("rocketDAONodeTrustedSettingsMembers"));
            // Node is trusted
            if (rocketDaoNodeTrusted.getMemberIsValid(msg.sender)) {
                require(rocketDaoNodeTrusted.getMemberUnbondedValidatorCount(msg.sender) < rocketDaoNodeTrustedSettingsMembers.getMinipoolUnbondedMax(), "Trusted node member would exceed the amount of unbonded minipools allowed");
                uint256 maxFee = rocketDAOProtocolSettingsNetwork.getMaximumNodeFee();
                require(nodeFee > maxFee.mul(rocketDaoNodeTrustedSettingsMembers.getMinipoolUnbondedMinFee()).div(1 ether), "Current commission rate is not high enough to create unbonded minipools");
            }
            // Node is not trusted - it cannot create unbonded minipools
            else {
                revert("Only members of the trusted node DAO may create unbonded minipools");
            }
        }
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Create minipool
        RocketMinipoolInterface minipool = rocketMinipoolManager.createMinipool(msg.sender, depositType);
        // Transfer deposit to minipool
        minipool.nodeDeposit{value: msg.value}();
        // Assign deposits if enabled
        if (rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) {
            RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
            rocketDepositPool.assignDeposits();
        }
    }

}
