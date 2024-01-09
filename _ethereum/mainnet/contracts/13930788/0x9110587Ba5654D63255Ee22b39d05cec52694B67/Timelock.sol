pragma solidity ^0.8.0;

import "./Interfaces.sol";
import "./SafeMath.sol";

contract Timelock {
    using SafeMath for uint;

    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 30 days;

    address public admin;


    mapping(address => bool) public isAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(uint delay_) public {
        isAdmin[msg.sender] = true;
        delay = delay_;
    }

    fallback() external payable { }

    function setDelay(uint delay_) public {
        require(isAdmin[msg.sender], "addAdmin : Call must from Admin!");
        delay = delay_;
    }


    function addAdmin(address admin_) public {
        require(isAdmin[msg.sender], "addAdmin : Call must from Admin!");
        isAdmin[admin_] = true;
    }

    function removeAdmin(address admin_) public {
        require(isAdmin[msg.sender], "addAdmin : Call must from Admin!");
        require(isAdmin[admin_], "addAdmin : admin_ must be Admin!");
        require(admin_ != msg.sender, "addAdmin : can not remove current!");
        isAdmin[admin_] = false;
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(isAdmin[msg.sender], "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(isAdmin[msg.sender], "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(isAdmin[msg.sender], "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function transferOwnership(address target_, address newOwner_) external {
        require(isAdmin[msg.sender], "addAdmin : Call must from Admin!");
        IOwnership(target_).transferOwnership(newOwner_);
    }
}