// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./SafeMath.sol";


/// @title Governance timelock smart contract
/// @author D-ETF.com
/// @dev The Timelock contract can modify system parameters, logic, and contracts in a 'time-delayed, opt-out' upgrade pattern.
/// The Timelock has a hard-coded minimum delay of 2 days, which is the least amount of notice possible for a governance action.
/// Each proposed action will be published at a minimum of 2 days in the future from the time of announcement.
/// Major upgrades, such as changing the risk system, may have a 14 day delay.
contract Timelock {
    using SafeMath for uint256;

    uint256 public delay;
    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 1 hours; // 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;

    mapping (bytes32 => bool) public queuedTransactions;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature,  bytes data, uint256 eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature,  bytes data, uint256 eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    //  --------------------
    //  CONSTRUCTOR
    //  --------------------

    constructor(address admin_, uint256 delay_) {
        require(delay_ >= MINIMUM_DELAY, "Timelock: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
    }

    fallback () external payable {
        // Empty fallback
    }

    receive () external payable {
        // Empty receive
    }


    //  --------------------
    //  SETTERS
    //  --------------------


    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), "setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "queueTransaction: Call must come from admin.");
        require(eta >= block.timestamp.add(delay), "queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "executeTransaction: Transaction hasn't been queued.");
        require(block.timestamp >= eta, "executeTransaction: Transaction hasn't surpassed time lock.");
        require(block.timestamp <= eta.add(GRACE_PERIOD), "executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}
