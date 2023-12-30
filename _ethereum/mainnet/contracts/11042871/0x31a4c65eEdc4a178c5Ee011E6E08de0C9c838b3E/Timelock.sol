// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Initializable.sol";


contract Timelock is Initializable, Ownable {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin_);
    event NewPendingAdmin(address indexed newPendingAdmin_);
    event NewDelay(uint256 indexed newDelay_);
    event NewGracePeriod(uint256 indexed newGracePerios_);
    event CancelTransaction(
        bytes32 indexed txHash_,
        address indexed target_,
        uint256 value_,
        string signature_,
        bytes data_,
        uint256 eta_
    );
    event ExecuteTransaction(
        bytes32 indexed txHash_,
        address indexed target_,
        uint256 value_,
        string signature_,
        bytes data_,
        uint256 eta_
    );
    event QueueTransaction(
        bytes32 indexed txHash_,
        address indexed target_,
        uint256 value_,
        string signature_,
        bytes data_,
        uint256 eta_
    );

    
    address public admin;
    address public pendingAdmin;
    
    // The amount of delay after which a delay can a queued can be executed.
    uint256 public delay = 1 days;
    // The the period within which an queued proposal can be executed.
    uint256 public gracePeriod = 7 days;

    mapping(bytes32 => bool) public queuedTransactions;

    /**
     * @notice Initializes timelock contract with the address of the governor/admin
     * @param admin_ Address of the timelock admin.
     */
    function initialize(address admin_)
        external
        onlyOwner
        initializer
    {
        admin = admin_;
    }

    receive() external payable {}

    /**
     * @notice Sets the amount of time after which a proposal that has been queued can be executed.
     * @param delay_ The amount of delay to set.
     */
    function setDelay(uint256 delay_) public onlyOwner {
        require(
            delay_ >= 0 && delay_ < gracePeriod,
            "Timelock::setDelay: Delay must not be greater equal to zero and less than gracePeriod"
        );
        delay = delay_;

        emit NewDelay(delay);
    }

    /**
     * @notice Sets the amount of time within which a queued proposal can be executed.
     * @param gracePeriod_ The new grace period to be set.
     */
    function setGracePeriod(uint256 gracePeriod_) public onlyOwner {
        require(
            gracePeriod_ > delay,
            "Timelock::gracePeriod: Grace period must be greater delay"
        );
        gracePeriod = gracePeriod_;

        emit NewGracePeriod(gracePeriod);
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin,
            "Timelock::acceptAdmin: Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public onlyOwner {  
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
        require(
            msg.sender == admin,
            "Timelock::queueTransaction: Call must come from admin."
        );
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
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
        require(
            msg.sender == admin,
            "Timelock::cancelTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
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
        require(
            msg.sender == admin,
            "Timelock::executeTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta.add(gracePeriod),
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}
