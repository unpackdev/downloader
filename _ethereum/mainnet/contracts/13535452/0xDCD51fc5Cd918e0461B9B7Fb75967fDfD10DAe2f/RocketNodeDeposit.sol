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
    function deposit(uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) override external payable onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Check deposits are enabled
        checkDepositsEnabled();
        // Check minipool doesn't exist or previously exist
        require(!rocketMinipoolManager.getMinipoolExists(_expectedMinipoolAddress) && !rocketMinipoolManager.getMinipoolDestroyed(_expectedMinipoolAddress), "Minipool already exists or was previously destroyed");
        // Check node fee
        checkNodeFee(_minimumNodeFee);
        // Get Deposit type
        MinipoolDeposit depositType = getDepositType(msg.value);
        // Check it's a valid deposit size
        require(depositType != MinipoolDeposit.None, "Invalid node deposit amount");
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Create minipool
        RocketMinipoolInterface minipool = rocketMinipoolManager.createMinipool(msg.sender, depositType, _salt);
        // Ensure minipool address matches expected
        require(address(minipool) == _expectedMinipoolAddress, "Unexpected minipool address");
        // Transfer deposit to minipool
        minipool.nodeDeposit{value: msg.value}(_validatorPubkey, _validatorSignature, _depositDataRoot);
        // Assign deposits if enabled
        assignDeposits();
    }

    // Returns the minipool deposit enum value correseponding to the supplied deposit amount
    function getDepositType(uint256 _amount) public override view returns (MinipoolDeposit) {
        // Get contract
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Get deposit type by node deposit amount
        if (_amount == rocketDAOProtocolSettingsMinipool.getFullDepositNodeAmount()) { return MinipoolDeposit.Full; }
        else if (_amount == rocketDAOProtocolSettingsMinipool.getHalfDepositNodeAmount()) { return MinipoolDeposit.Half; }
        // Invalid deposit amount
        return MinipoolDeposit.None;
    }

    function checkNodeFee(uint256 _minimumNodeFee) private view {
        // Load contracts
        RocketNetworkFeesInterface rocketNetworkFees = RocketNetworkFeesInterface(getContractAddress("rocketNetworkFees"));
        // Check current node fee
        uint256 nodeFee = rocketNetworkFees.getNodeFee();
        require(nodeFee >= _minimumNodeFee, "Minimum node fee exceeds current network node fee");
    }

    function checkDepositsEnabled() private view {
        // Get contracts
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getDepositEnabled(), "Node deposits are currently disabled");
    }

    function assignDeposits() private {
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        if (rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) {
            RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
            rocketDepositPool.assignDeposits();
        }
    }
}
